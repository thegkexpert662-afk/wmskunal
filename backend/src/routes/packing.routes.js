const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

const createSchema = z.object({ orderId: z.string().uuid() });
const packageSchema = z.object({
  packageNo: z.string().trim().min(1).max(60),
  packageType: z.string().trim().min(1).max(50).default('Box'),
  weight: z.coerce.number().min(0).default(0),
  length: z.coerce.number().min(0).default(0),
  width: z.coerce.number().min(0).default(0),
  height: z.coerce.number().min(0).default(0),
});
const packSchema = z.object({
  orderItemId: z.string().uuid(),
  packageId: z.string().uuid(),
  quantity: z.coerce.number().positive(),
});

async function assigned(req) {
  return getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
}

function warehouseScope(ids, params, alias = 'o') {
  if (!ids.length) return '';
  params.push(ids);
  return ` AND ${alias}.warehouse_id = ANY($${params.length}::uuid[])`;
}

async function accessiblePacking(req, id, db = pool, forUpdate = false) {
  const ids = await assigned(req);
  const params = [id, req.tenant.companyId];
  const scope = warehouseScope(ids, params, 'o');
  return db.query(
    `SELECT pk.*,o.order_no,o.status order_status,o.required_date,o.remarks,
            o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
            c.client_code,c.name client_name,u.full_name packed_by_name
     FROM packing pk
     JOIN orders o ON o.id=pk.order_id
     JOIN warehouses w ON w.id=o.warehouse_id
     JOIN clients c ON c.id=o.client_id
     LEFT JOIN users u ON u.id=pk.packed_by
     WHERE pk.id=$1 AND pk.company_id=$2${scope}
     ${forUpdate ? 'FOR UPDATE OF pk,o' : ''}
     LIMIT 1`,
    params,
  );
}

router.get('/pending', requirePermission('packing.read'), async (req,res,next)=>{
  try {
    const ids=await assigned(req);
    const params=[req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const result=await pool.query(
      `SELECT o.id,o.order_no,o.status,o.required_date,o.created_at,o.warehouse_id,
              w.code warehouse_code,w.name warehouse_name,
              c.id client_id,c.client_code,c.name client_name,
              COUNT(oi.id)::int item_count,
              COALESCE(SUM(oi.picked_qty),0) picked_qty
       FROM orders o
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       JOIN order_items oi ON oi.order_id=o.id
       WHERE o.company_id=$1 AND o.status='picking'
         AND NOT EXISTS (
           SELECT 1 FROM packing pk
           WHERE pk.order_id=o.id AND pk.status IN ('pending','in_progress')
         )
         AND NOT EXISTS (
           SELECT 1 FROM order_items oi2
           WHERE oi2.order_id=o.id AND oi2.picked_qty < oi2.ordered_qty
         )
         ${scope}
       GROUP BY o.id,w.code,w.name,c.id,c.client_code,c.name
       ORDER BY o.required_date NULLS LAST,o.created_at
       LIMIT 200`,params);
    res.json({orders:result.rows});
  } catch(e){next(e);}
});

router.get('/tasks', requirePermission('packing.read'), async (req,res,next)=>{
  try {
    const ids=await assigned(req);
    const params=[req.tenant.companyId];
    let scope=warehouseScope(ids,params,'o');
    if(req.query.status){
      params.push(String(req.query.status));
      scope += ` AND pk.status=$${params.length}`;
    }
    const result=await pool.query(
      `SELECT pk.id,pk.packing_no,pk.status,pk.packed_by,pk.total_packages,
              pk.created_at,pk.completed_at,
              o.id order_id,o.order_no,o.status order_status,o.warehouse_id,
              w.code warehouse_code,w.name warehouse_name,c.name client_name,
              u.full_name packed_by_name,
              COUNT(DISTINCT pi.id)::int packed_lines,
              COALESCE(SUM(pi.quantity),0) packed_qty
       FROM packing pk
       JOIN orders o ON o.id=pk.order_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       LEFT JOIN users u ON u.id=pk.packed_by
       LEFT JOIN packing_items pi ON pi.packing_id=pk.id
       WHERE pk.company_id=$1 ${scope}
       GROUP BY pk.id,o.id,w.code,w.name,c.name,u.full_name
       ORDER BY pk.created_at DESC
       LIMIT 300`,params);
    res.json({tasks:result.rows});
  } catch(e){next(e);}
});

router.get('/tasks/:id', requirePermission('packing.read'), async (req,res,next)=>{
  try {
    const task=await accessiblePacking(req,req.params.id);
    if(!task.rowCount)return res.status(404).json({error:{code:'PACKING_NOT_FOUND',message:'Packing task not found.'}});
    const t=task.rows[0];
    const items=await pool.query(
      `SELECT oi.id order_item_id,oi.product_id,p.sku,p.name product_name,p.uom,
              oi.ordered_qty,oi.picked_qty,
              COALESCE(SUM(pi.quantity),0) packed_qty,
              GREATEST(oi.picked_qty-COALESCE(SUM(pi.quantity),0),0) remaining_qty
       FROM order_items oi
       JOIN products p ON p.id=oi.product_id
       LEFT JOIN packing_items pi ON pi.order_item_id=oi.id AND pi.packing_id=$1
       WHERE oi.order_id=$2
       GROUP BY oi.id,p.id,p.sku,p.name,p.uom
       ORDER BY p.name`,
      [t.id,t.order_id]);
    const packages=await pool.query(
      `SELECT id,package_no,package_type,weight,length,width,height,created_at
       FROM packages WHERE packing_id=$1 ORDER BY created_at,package_no`,
      [t.id]);
    res.json({task:t,items:items.rows,packages:packages.rows});
  } catch(e){next(e);}
});

router.post('/tasks', requirePermission('packing.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try {
    const input=createSchema.parse(req.body);
    await db.query('BEGIN');
    const ids=await assigned(req);
    const params=[input.orderId,req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const orderResult=await db.query(
      `SELECT o.*,c.client_code,c.name client_name,w.code warehouse_code,w.name warehouse_name
       FROM orders o
       JOIN clients c ON c.id=o.client_id
       JOIN warehouses w ON w.id=o.warehouse_id
       WHERE o.id=$1 AND o.company_id=$2${scope}
       LIMIT 1 FOR UPDATE OF o`,params);
    if(!orderResult.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'ORDER_NOT_FOUND',message:'Order not found or outside your warehouse access.'}});
    }
    const order=orderResult.rows[0];
    if(order.status!=='picking'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'ORDER_NOT_READY_FOR_PACKING',message:'Order must be in picking status.'}});
    }
    const incomplete=await db.query(
      `SELECT COUNT(*)::int pending_items FROM order_items
       WHERE order_id=$1 AND picked_qty < ordered_qty`,[input.orderId]);
    if(Number(incomplete.rows[0].pending_items)>0){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PICKING_INCOMPLETE',message:'All order items must be fully picked before packing can start.'}});
    }
    const active=await db.query(
      `SELECT id FROM packing WHERE order_id=$1 AND status IN ('pending','in_progress') LIMIT 1 FOR UPDATE`,
      [input.orderId]);
    if(active.rowCount){
      await db.query('ROLLBACK');
      return res.status(409).json({error:{code:'ACTIVE_PACKING_EXISTS',message:'An active packing task already exists for this order.',taskId:active.rows[0].id}});
    }
    const packingNo=`PACK-${Date.now().toString().slice(-10)}`;
    const created=await db.query(
      `INSERT INTO packing(company_id,order_id,warehouse_id,packing_no,status,packed_by)
       VALUES($1,$2,$3,$4,'in_progress',$5) RETURNING *`,
      [req.tenant.companyId,input.orderId,order.warehouse_id,packingNo,req.user.sub]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'PACKING_TASK_CREATED','packing',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,created.rows[0].id,req.ip||null,req.get('user-agent')||null,
       JSON.stringify({orderId:input.orderId,orderNo:order.order_no,warehouseId:order.warehouse_id})]);
    await db.query('COMMIT');
    res.status(201).json({task:created.rows[0]});
  } catch(e) {
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid packing task request.'}});
    if(e.code==='23505')return res.status(409).json({error:{code:'ACTIVE_PACKING_EXISTS',message:'An active packing task already exists for this order.'}});
    next(e);
  } finally {db.release();}
});

router.post('/tasks/:id/packages', requirePermission('packing.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try {
    const input=packageSchema.parse(req.body);
    await db.query('BEGIN');
    const task=await accessiblePacking(req,req.params.id,db,true);
    if(!task.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'PACKING_NOT_FOUND',message:'Packing task not found.'}});
    }
    const t=task.rows[0];
    if(t.status!=='in_progress'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACKING_NOT_ACTIVE',message:'Packing task is not active.'}});
    }
    const pkg=await db.query(
      `INSERT INTO packages(company_id,packing_id,package_no,package_type,weight,length,width,height)
       VALUES($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [req.tenant.companyId,t.id,input.packageNo,input.packageType,input.weight,input.length,input.width,input.height]);
    await db.query(
      `UPDATE packing SET total_packages=total_packages+1,updated_at=NOW() WHERE id=$1`,[t.id]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,'PACKING_PACKAGE_CREATED','package',$3,$4::jsonb)`,
      [req.tenant.companyId,req.user.sub,pkg.rows[0].id,JSON.stringify({packingId:t.id,packageNo:input.packageNo})]);
    await db.query('COMMIT');
    res.status(201).json({package:pkg.rows[0]});
  } catch(e) {
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid package request.'}});
    if(e.code==='23505')return res.status(409).json({error:{code:'PACKAGE_ALREADY_EXISTS',message:'Package number already exists for this packing task.'}});
    next(e);
  } finally {db.release();}
});

router.post('/tasks/:id/pack', requirePermission('packing.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try {
    const input=packSchema.parse(req.body);
    await db.query('BEGIN');
    const task=await accessiblePacking(req,req.params.id,db,true);
    if(!task.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'PACKING_NOT_FOUND',message:'Packing task not found.'}});
    }
    const t=task.rows[0];
    if(t.status!=='in_progress'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACKING_NOT_ACTIVE',message:'Packing task is not active.'}});
    }
    const pkg=await db.query(
      `SELECT * FROM packages WHERE id=$1 AND packing_id=$2 AND company_id=$3 FOR UPDATE`,
      [input.packageId,t.id,req.tenant.companyId]);
    if(!pkg.rowCount){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'INVALID_PACKAGE',message:'Package does not belong to this packing task.'}});
    }
    const item=await db.query(
      `SELECT oi.id,oi.product_id,oi.ordered_qty,oi.picked_qty,p.sku,p.name product_name
       FROM order_items oi JOIN products p ON p.id=oi.product_id
       WHERE oi.id=$1 AND oi.order_id=$2 FOR UPDATE`,
      [input.orderItemId,t.order_id]);
    if(!item.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'ORDER_ITEM_NOT_FOUND',message:'Order item not found for this packing task.'}});
    }
    const existing=await db.query(
      `SELECT COALESCE(SUM(quantity),0) packed_qty
       FROM packing_items WHERE packing_id=$1 AND order_item_id=$2`,
      [t.id,input.orderItemId]);
    const packed=Number(existing.rows[0].packed_qty);
    const picked=Number(item.rows[0].picked_qty);
    const remaining=Math.max(picked-packed,0);
    if(input.quantity>remaining){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACK_QTY_EXCEEDS_REMAINING',message:`Only ${remaining} remains to pack for this item.`}});
    }
    const line=await db.query(
      `INSERT INTO packing_items(packing_id,package_id,order_item_id,product_id,quantity)
       VALUES($1,$2,$3,$4,$5) RETURNING *`,
      [t.id,input.packageId,item.rows[0].id,item.rows[0].product_id,input.quantity]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,'ORDER_ITEM_PACKED','packing_item',$3,$4::jsonb)`,
      [req.tenant.companyId,req.user.sub,line.rows[0].id,JSON.stringify({packingId:t.id,orderId:t.order_id,orderItemId:item.rows[0].id,packageId:input.packageId,quantity:input.quantity})]);
    await db.query('COMMIT');
    res.status(201).json({packingItem:line.rows[0]});
  } catch(e) {
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid packing request.'}});
    next(e);
  } finally {db.release();}
});

router.post('/tasks/:id/complete', requirePermission('packing.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try {
    await db.query('BEGIN');
    const task=await accessiblePacking(req,req.params.id,db,true);
    if(!task.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'PACKING_NOT_FOUND',message:'Packing task not found.'}});
    }
    const t=task.rows[0];
    if(t.status!=='in_progress'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACKING_NOT_ACTIVE',message:'Packing task is not active.'}});
    }
    const remaining=await db.query(
      `SELECT COUNT(*)::int pending_items
       FROM order_items oi
       WHERE oi.order_id=$1
         AND oi.picked_qty > COALESCE((SELECT SUM(pi.quantity) FROM packing_items pi WHERE pi.packing_id=$2 AND pi.order_item_id=oi.id),0)`,
      [t.order_id,t.id]);
    if(Number(remaining.rows[0].pending_items)>0){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACKING_INCOMPLETE',message:'All picked quantities must be packed before marking the order ready.'}});
    }
    if(Number(t.total_packages)<=0){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PACKAGE_REQUIRED',message:'Create at least one package before completing packing.'}});
    }
    const updated=await db.query(
      `UPDATE packing SET status='ready',completed_at=NOW(),updated_at=NOW() WHERE id=$1 RETURNING *`,[t.id]);
    const order=await db.query(
      `UPDATE orders SET status='packed',updated_at=NOW() WHERE id=$1 AND company_id=$2 AND status='picking' RETURNING *`,
      [t.order_id,req.tenant.companyId]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'PACKING_COMPLETED','packing',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,t.id,req.ip||null,req.get('user-agent')||null,
       JSON.stringify({orderId:t.order_id,orderNo:t.order_no,warehouseId:t.warehouse_id,totalPackages:t.total_packages})]);
    await db.query('COMMIT');
    res.json({task:updated.rows[0],order:order.rows[0]||null,nextStep:'dispatch'});
  } catch(e){await db.query('ROLLBACK').catch(()=>{});next(e);}
  finally{db.release();}
});

module.exports=router;
