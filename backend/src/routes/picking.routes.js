const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

const taskSchema = z.object({ orderId: z.string().uuid() });
const pickSchema = z.object({
  orderItemId: z.string().uuid(),
  locationId: z.string().uuid(),
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

async function accessibleOrder(req, orderId, db = pool, forUpdate = false) {
  const ids = await assigned(req);
  const params = [orderId, req.tenant.companyId];
  const scope = warehouseScope(ids, params, 'o');
  return db.query(
    `SELECT o.*, c.client_code, c.name client_name,
            w.code warehouse_code, w.name warehouse_name
     FROM orders o
     JOIN clients c ON c.id=o.client_id
     JOIN warehouses w ON w.id=o.warehouse_id
     WHERE o.id=$1 AND o.company_id=$2${scope}
     ${forUpdate ? 'FOR UPDATE OF o' : ''}
     LIMIT 1`,
    params,
  );
}

router.get('/pending', requirePermission('picking.read'), async (req,res,next)=>{
  try {
    const ids=await assigned(req);
    const params=[req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const result=await pool.query(
      `SELECT o.id,o.order_no,o.status,o.required_date,o.created_at,
              o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
              c.id client_id,c.client_code,c.name client_name,
              COUNT(oi.id)::int item_count,
              COALESCE(SUM(oi.ordered_qty),0) total_qty,
              COALESCE(SUM(oi.picked_qty),0) picked_qty,
              COALESCE(SUM(oi.ordered_qty-oi.picked_qty),0) remaining_qty
       FROM orders o
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       JOIN order_items oi ON oi.order_id=o.id
       WHERE o.company_id=$1
         AND o.status IN ('allocated','picking')
         ${scope}
       GROUP BY o.id,w.code,w.name,c.id,c.client_code,c.name
       ORDER BY o.required_date NULLS LAST,o.created_at
       LIMIT 200`,params);
    res.json({orders:result.rows});
  } catch(e){next(e);}
});

router.get('/tasks', requirePermission('picking.read'), async (req,res,next)=>{
  try {
    const ids=await assigned(req);
    const params=[req.tenant.companyId];
    let scope=warehouseScope(ids,params,'o');
    if(req.query.status){
      params.push(String(req.query.status));
      scope += ` AND pt.status=$${params.length}`;
    }
    const result=await pool.query(
      `SELECT pt.id,pt.status,pt.picker_id,pt.created_at,pt.completed_at,
              o.id order_id,o.order_no,o.status order_status,
              o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
              c.name client_name,
              u.full_name picker_name,
              COUNT(pi.id)::int pick_line_count,
              COALESCE(SUM(pi.quantity),0) picked_qty
       FROM picking_tasks pt
       JOIN orders o ON o.id=pt.order_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       LEFT JOIN users u ON u.id=pt.picker_id
       LEFT JOIN picking_items pi ON pi.picking_task_id=pt.id
       WHERE pt.company_id=$1 ${scope}
       GROUP BY pt.id,o.id,w.code,w.name,c.name,u.full_name
       ORDER BY pt.created_at DESC
       LIMIT 300`,params);
    res.json({tasks:result.rows});
  } catch(e){next(e);}
});

router.get('/tasks/:id', requirePermission('picking.read'), async (req,res,next)=>{
  try {
    const ids=await assigned(req);
    const params=[req.params.id,req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const task=await pool.query(
      `SELECT pt.*,o.order_no,o.status order_status,o.required_date,o.remarks,
              o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
              c.client_code,c.name client_name,u.full_name picker_name
       FROM picking_tasks pt
       JOIN orders o ON o.id=pt.order_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       LEFT JOIN users u ON u.id=pt.picker_id
       WHERE pt.id=$1 AND pt.company_id=$2 ${scope}
       LIMIT 1`,params);
    if(!task.rowCount)return res.status(404).json({error:{code:'PICKING_TASK_NOT_FOUND',message:'Picking task not found.'}});
    const t=task.rows[0];
    const items=await pool.query(
      `SELECT oi.id order_item_id,oi.product_id,p.sku,p.name product_name,p.uom,
              oi.ordered_qty,oi.picked_qty,
              GREATEST(oi.ordered_qty-oi.picked_qty,0) remaining_qty,
              COALESCE(json_agg(
                json_build_object(
                  'id',pi.id,'locationId',pi.location_id,'locationCode',wl.code,
                  'quantity',pi.quantity
                ) ORDER BY wl.code
              ) FILTER (WHERE pi.id IS NOT NULL),'[]'::json) pick_lines
       FROM order_items oi
       JOIN products p ON p.id=oi.product_id
       LEFT JOIN picking_items pi ON pi.order_item_id=oi.id AND pi.picking_task_id=$1
       LEFT JOIN warehouse_locations wl ON wl.id=pi.location_id
       WHERE oi.order_id=$2
       GROUP BY oi.id,p.id,p.sku,p.name,p.uom
       ORDER BY p.name`,
      [req.params.id,t.order_id]);
    const plan=[];
    for(const item of items.rows){
      const remaining=Number(item.remaining_qty);
      if(remaining<=0)continue;
      const stock=await pool.query(
        `SELECT i.location_id,wl.code location_code,
                i.quantity,i.reserved_quantity,
                GREATEST(i.quantity-i.reserved_quantity,0) available_quantity
         FROM inventory i
         JOIN warehouse_locations wl ON wl.id=i.location_id
         WHERE i.company_id=$1 AND i.product_id=$2 AND i.warehouse_id=$3
           AND i.location_id IS NOT NULL AND wl.is_active=TRUE
           AND GREATEST(i.quantity-i.reserved_quantity,0)>0
         ORDER BY wl.code`,
        [t.company_id,item.product_id,t.warehouse_id]);
      let left=remaining;
      for(const row of stock){
        if(left<=0)break;
        const take=Math.min(left,Number(row.available_quantity));
        if(take>0)plan.push({orderItemId:item.order_item_id,productId:item.product_id,sku:item.sku,productName:item.product_name,locationId:row.location_id,locationCode:row.location_code,availableQuantity:Number(row.available_quantity),suggestedPickQuantity:take});
        left-=take;
      }
    }
    res.json({task:t,items:items.rows,pickPlan:plan});
  }catch(e){next(e);}
});

router.post('/tasks', requirePermission('picking.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=taskSchema.parse(req.body);
    await db.query('BEGIN');
    const orderResult=await accessibleOrder(req,input.orderId,db,true);
    if(!orderResult.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'ORDER_NOT_FOUND',message:'Order not found or outside your warehouse access.'}});
    }
    const order=orderResult.rows[0];
    if(!['allocated','picking'].includes(order.status)){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'ORDER_NOT_READY_FOR_PICKING',message:'Order must be allocated or already in picking status.'}});
    }
    const active=await db.query(`SELECT id FROM picking_tasks WHERE order_id=$1 AND status IN ('pending','in_progress') LIMIT 1 FOR UPDATE`,[input.orderId]);
    if(active.rowCount){
      await db.query('ROLLBACK');
      return res.status(409).json({error:{code:'ACTIVE_PICKING_TASK_EXISTS',message:'An active picking task already exists for this order.',taskId:active.rows[0].id}});
    }
    const task=await db.query(
      `INSERT INTO picking_tasks(company_id,order_id,status,picker_id)
       VALUES($1,$2,'in_progress',$3) RETURNING *`,
      [req.tenant.companyId,input.orderId,req.user.sub]);
    if(order.status==='allocated'){
      await db.query(`UPDATE orders SET status='picking',updated_at=NOW() WHERE id=$1 AND company_id=$2`,[input.orderId,req.tenant.companyId]);
    }
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'PICKING_TASK_CREATED','picking_task',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,task.rows[0].id,req.ip||null,req.get('user-agent')||null,JSON.stringify({orderId:input.orderId,orderNo:order.order_no,warehouseId:order.warehouse_id})]);
    await db.query('COMMIT');
    res.status(201).json({task:task.rows[0]});
  }catch(e){
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid picking task request.'}});
    if(e.code==='23505')return res.status(409).json({error:{code:'ACTIVE_PICKING_TASK_EXISTS',message:'An active picking task already exists for this order.'}});
    next(e);
  }finally{db.release();}
});

router.post('/tasks/:id/pick', requirePermission('picking.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=pickSchema.parse(req.body);
    await db.query('BEGIN');

    const ids=await assigned(req);
    const params=[req.params.id,req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const taskResult=await db.query(
      `SELECT pt.*,o.order_no,o.status order_status,o.warehouse_id
       FROM picking_tasks pt JOIN orders o ON o.id=pt.order_id
       WHERE pt.id=$1 AND pt.company_id=$2 ${scope}
       FOR UPDATE OF pt,o`,params);
    if(!taskResult.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'PICKING_TASK_NOT_FOUND',message:'Picking task not found or outside your warehouse access.'}});
    }
    const task=taskResult.rows[0];
    if(task.status!=='in_progress'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PICKING_TASK_NOT_ACTIVE',message:'Picking task is not active.'}});
    }
    if(!['picking'].includes(task.order_status)){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'ORDER_NOT_IN_PICKING',message:'Order is not currently in picking status.'}});
    }

    const item=await db.query(
      `SELECT oi.id,oi.product_id,oi.ordered_qty,oi.picked_qty,p.sku,p.name product_name
       FROM order_items oi JOIN products p ON p.id=oi.product_id
       WHERE oi.id=$1 AND oi.order_id=$2 FOR UPDATE`,
      [input.orderItemId,task.order_id]);
    if(!item.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'ORDER_ITEM_NOT_FOUND',message:'Order item not found for this task.'}});
    }
    const orderItem=item.rows[0];
    const remaining=Number(orderItem.ordered_qty)-Number(orderItem.picked_qty);
    if(input.quantity>remaining){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PICK_QTY_EXCEEDS_REMAINING','message':'Pick quantity exceeds the remaining order quantity.'}});
    }

    const location=await db.query(
      `SELECT wl.id,wl.code,wl.warehouse_id
       FROM warehouse_locations wl
       JOIN warehouses w ON w.id=wl.warehouse_id
       WHERE wl.id=$1 AND wl.warehouse_id=$2 AND w.company_id=$3
         AND wl.is_active=TRUE AND w.is_active=TRUE`,
      [input.locationId,task.warehouse_id,req.tenant.companyId]);
    if(!location.rowCount){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'INVALID_LOCATION',message:'Location is invalid or outside the order warehouse.'}});
    }

    const inv=await db.query(
      `SELECT id,quantity,reserved_quantity
       FROM inventory
       WHERE company_id=$1 AND product_id=$2 AND warehouse_id=$3
         AND location_id=$4
       FOR UPDATE`,
      [req.tenant.companyId,orderItem.product_id,task.warehouse_id,input.locationId]);
    if(!inv.rowCount){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'INSUFFICIENT_STOCK',message:'No stock is available at this location.'}});
    }
    const current=Number(inv.rows[0].quantity);
    const reserved=Number(inv.rows[0].reserved_quantity);
    const available=Math.max(current-reserved,0);
    if(input.quantity>available){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'INSUFFICIENT_STOCK',message:`Only ${available} is available at this location.`}});
    }

    await db.query(
      `UPDATE inventory SET quantity=quantity-$1,updated_at=NOW() WHERE id=$2`,
      [input.quantity,inv.rows[0].id]);
    const line=await db.query(
      `INSERT INTO picking_items(picking_task_id,order_item_id,location_id,quantity)
       VALUES($1,$2,$3,$4) RETURNING *`,
      [task.id,orderItem.id,input.locationId,input.quantity]);
    const updatedItem=await db.query(
      `UPDATE order_items SET picked_qty=picked_qty+$1
       WHERE id=$2 RETURNING *`,
      [input.quantity,orderItem.id]);

    await db.query(
      `INSERT INTO inventory_transactions(
        company_id,product_id,warehouse_id,location_id,transaction_type,quantity,
        reference_type,reference_id,created_by,source_location_id)
       VALUES($1,$2,$3,$4,'pick',$5,'picking_task',$6,$7,$4)`,
      [req.tenant.companyId,orderItem.product_id,task.warehouse_id,input.locationId,input.quantity,task.id,req.user.sub]);

    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'STOCK_PICKED','picking_item',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,line.rows[0].id,req.ip||null,req.get('user-agent')||null,JSON.stringify({taskId:task.id,orderId:task.order_id,orderItemId:orderItem.id,productId:orderItem.product_id,warehouseId:task.warehouse_id,locationId:input.locationId,quantity:input.quantity,remainingOrderQty:remaining-input.quantity})]);

    await db.query('COMMIT');
    res.status(201).json({pickingItem:line.rows[0],orderItem:updatedItem.rows[0]});
  }catch(e){
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid pick request.'}});
    next(e);
  }finally{db.release();}
});

router.post('/tasks/:id/complete', requirePermission('picking.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try{
    await db.query('BEGIN');
    const ids=await assigned(req);
    const params=[req.params.id,req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const taskResult=await db.query(
      `SELECT pt.*,o.order_no,o.status order_status,o.warehouse_id
       FROM picking_tasks pt JOIN orders o ON o.id=pt.order_id
       WHERE pt.id=$1 AND pt.company_id=$2 ${scope}
       FOR UPDATE OF pt,o`,params);
    if(!taskResult.rowCount){
      await db.query('ROLLBACK');
      return res.status(404).json({error:{code:'PICKING_TASK_NOT_FOUND',message:'Picking task not found.'}});
    }
    const task=taskResult.rows[0];
    if(task.status!=='in_progress'){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PICKING_TASK_NOT_ACTIVE',message:'Picking task is not active.'}});
    }
    const remaining=await db.query(
      `SELECT COUNT(*)::int pending_items
       FROM order_items
       WHERE order_id=$1 AND picked_qty<ordered_qty`,
      [task.order_id]);
    if(Number(remaining.rows[0].pending_items)>0){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'PICKING_INCOMPLETE',message:'All order items must be fully picked before completing the task.'}});
    }
    const updated=await db.query(
      `UPDATE picking_tasks SET status='completed',completed_at=NOW() WHERE id=$1 RETURNING *`,
      [task.id]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'PICKING_TASK_COMPLETED','picking_task',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,task.id,req.ip||null,req.get('user-agent')||null,JSON.stringify({orderId:task.order_id,orderNo:task.order_no,warehouseId:task.warehouse_id})]);
    await db.query('COMMIT');
    res.json({task:updated.rows[0],orderStatus:task.order_status,nextStep:'packing'});
  }catch(e){await db.query('ROLLBACK').catch(()=>{});next(e);}
  finally{db.release();}
});

module.exports=router;
