const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

const createSchema = z.object({
  orderId: z.string().uuid().optional(),
  invoiceId: z.string().uuid().optional(),
  warehouseId: z.string().uuid(),
  reason: z.string().trim().min(1).max(1000),
  items: z.array(z.object({
    orderItemId: z.string().uuid(),
    returnedQty: z.coerce.number().positive(),
  })).min(1),
}).superRefine((v, ctx) => {
  if (!v.orderId && !v.invoiceId) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['orderId'],
      message: 'Order or invoice is required.',
    });
  }
  const seen = new Set();
  v.items.forEach((item, i) => {
    if (seen.has(item.orderItemId)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['items', i, 'orderItemId'],
        message: 'Duplicate order item is not allowed.',
      });
    }
    seen.add(item.orderItemId);
  });
});

const qcSchema = z.object({
  items: z.array(z.object({
    returnItemId: z.string().uuid(),
    acceptedQty: z.coerce.number().min(0),
    damagedQty: z.coerce.number().min(0),
    rejectedQty: z.coerce.number().min(0),
    locationId: z.string().uuid().optional(),
    remarks: z.string().trim().max(1000).optional(),
  })).min(1),
});

const statusSchema = z.object({
  status: z.enum(['cancelled']),
});

async function assigned(req) {
  return getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
}

function scopeFor(ids, params, alias = 'r') {
  if (!ids.length) return '';
  params.push(ids);
  return ` AND ${alias}.warehouse_id = ANY($${params.length}::uuid[])`;
}

async function getReturn(req, id, db = pool, forUpdate = false) {
  const ids = await assigned(req);
  const params = [id, req.tenant.companyId];
  const scope = scopeFor(ids, params);
  return db.query(
    `SELECT r.*,c.client_code,c.name client_name,
            w.code warehouse_code,w.name warehouse_name,
            o.order_no,o.status order_status,
            i.invoice_no,
            u.full_name created_by_name
     FROM returns r
     LEFT JOIN clients c ON c.id=r.client_id
     LEFT JOIN warehouses w ON w.id=r.warehouse_id
     LEFT JOIN orders o ON o.id=r.order_id
     LEFT JOIN invoices i ON i.id=r.invoice_id
     LEFT JOIN users u ON u.id=r.created_by
     WHERE r.id=$1 AND r.company_id=$2${scope}
     ${forUpdate ? 'FOR UPDATE OF r' : ''}
     LIMIT 1`,
    params,
  );
}

router.get('/pending', requirePermission('return.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    const scope = scopeFor(ids, params);
    const result = await pool.query(
      `SELECT r.*,c.client_code,c.name client_name,o.order_no,
              w.code warehouse_code,w.name warehouse_name,
              COUNT(ri.id)::int item_count,
              COALESCE(SUM(ri.returned_qty),0) total_returned_qty
       FROM returns r
       LEFT JOIN clients c ON c.id=r.client_id
       LEFT JOIN orders o ON o.id=r.order_id
       LEFT JOIN warehouses w ON w.id=r.warehouse_id
       LEFT JOIN return_items ri ON ri.return_id=r.id
       WHERE r.company_id=$1
         AND r.status IN ('requested','gate_in_pending','qc_pending')${scope}
       GROUP BY r.id,c.id,o.id,w.id
       ORDER BY r.created_at DESC
       LIMIT 200`,
      params,
    );
    res.json({ returns: result.rows });
  } catch (e) {
    next(e);
  }
});

router.get('/', requirePermission('return.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    let scope = scopeFor(ids, params);
    if (req.query.status) {
      params.push(String(req.query.status));
      scope += ` AND r.status=$${params.length}`;
    }
    const result = await pool.query(
      `SELECT r.*,c.client_code,c.name client_name,o.order_no,
              w.code warehouse_code,w.name warehouse_name,
              i.invoice_no,
              COUNT(ri.id)::int item_count,
              COALESCE(SUM(ri.returned_qty),0) total_returned_qty
       FROM returns r
       LEFT JOIN clients c ON c.id=r.client_id
       LEFT JOIN orders o ON o.id=r.order_id
       LEFT JOIN warehouses w ON w.id=r.warehouse_id
       LEFT JOIN invoices i ON i.id=r.invoice_id
       LEFT JOIN return_items ri ON ri.return_id=r.id
       WHERE r.company_id=$1${scope}
       GROUP BY r.id,c.id,o.id,w.id,i.id
       ORDER BY r.created_at DESC
       LIMIT 300`,
      params,
    );
    res.json({ returns: result.rows });
  } catch (e) {
    next(e);
  }
});

router.get('/:id', requirePermission('return.read'), async (req, res, next) => {
  try {
    const result = await getReturn(req, req.params.id);
    if (!result.rowCount) {
      return res.status(404).json({
        error: { code: 'RETURN_NOT_FOUND', message: 'Return not found.' },
      });
    }

    const items = await pool.query(
      `SELECT ri.*,oi.ordered_qty,oi.picked_qty,oi.dispatched_qty,
              p.sku,p.name product_name,p.uom
       FROM return_items ri
       JOIN products p ON p.id=ri.product_id
       LEFT JOIN order_items oi ON oi.id=ri.order_item_id
       WHERE ri.return_id=$1
       ORDER BY p.name`,
      [req.params.id],
    );
    res.json({ return: { ...result.rows[0], items: items.rows } });
  } catch (e) {
    next(e);
  }
});

router.get('/source/orders', requirePermission('return.create'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    const scope = scopeFor(ids, params, 'o');
    const result = await pool.query(
      `SELECT o.id,o.order_no,o.status,o.required_date,o.warehouse_id,
              c.name client_name,w.code warehouse_code,w.name warehouse_name,
              COUNT(oi.id)::int item_count,
              COALESCE(SUM(oi.dispatched_qty),0) dispatched_qty
       FROM orders o
       JOIN clients c ON c.id=o.client_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN order_items oi ON oi.order_id=o.id
       WHERE o.company_id=$1
         AND o.status IN ('dispatched','delivered')${scope}
       GROUP BY o.id,c.id,w.id
       HAVING COALESCE(SUM(oi.dispatched_qty),0)>0
       ORDER BY o.created_at DESC
       LIMIT 200`,
      params,
    );
    res.json({ orders: result.rows });
  } catch (e) {
    next(e);
  }
});

router.post('/', requirePermission('return.create'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = createSchema.parse(req.body);
    await db.query('BEGIN');

    const warehouse = await db.query(
      'SELECT id,company_id,is_active FROM warehouses WHERE id=$1 AND company_id=$2 FOR UPDATE',
      [input.warehouseId, req.tenant.companyId],
    );
    if (!warehouse.rowCount || !warehouse.rows[0].is_active) {
      await db.query('ROLLBACK');
      return res.status(400).json({
        error: { code: 'INVALID_WAREHOUSE', message: 'Warehouse is invalid or inactive.' },
      });
    }

    let orderId = input.orderId || null;
    let invoiceId = input.invoiceId || null;

    if (invoiceId) {
      const invoice = await db.query(
        'SELECT id,order_id,client_id FROM invoices WHERE id=$1 AND company_id=$2',
        [invoiceId, req.tenant.companyId],
      );
      if (!invoice.rowCount) {
        await db.query('ROLLBACK');
        return res.status(404).json({ error: { code: 'INVOICE_NOT_FOUND', message: 'Invoice not found.' } });
      }
      if (orderId && invoice.rows[0].order_id && invoice.rows[0].order_id !== orderId) {
        await db.query('ROLLBACK');
        return res.status(400).json({ error: { code: 'ORDER_INVOICE_MISMATCH', message: 'Invoice does not belong to the selected order.' } });
      }
      orderId = orderId || invoice.rows[0].order_id;
    }

    if (!orderId) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'ORDER_REQUIRED', message: 'A return must resolve to an original order.' } });
    }

    const order = await db.query(
      `SELECT o.*,c.id client_id
       FROM orders o JOIN clients c ON c.id=o.client_id
       WHERE o.id=$1 AND o.company_id=$2 FOR UPDATE`,
      [orderId, req.tenant.companyId],
    );
    if (!order.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'ORDER_NOT_FOUND', message: 'Original order not found.' } });
    }
    if (!['dispatched','delivered'].includes(order.rows[0].status)) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'ORDER_NOT_RETURNABLE', message: 'Only dispatched or delivered orders can be returned.' } });
    }
    if (order.rows[0].warehouse_id !== input.warehouseId) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'WAREHOUSE_MISMATCH', message: 'Return warehouse must match the original order warehouse.' } });
    }

    const ids = await assigned(req);
    if (ids.length && !ids.includes(input.warehouseId)) {
      await db.query('ROLLBACK');
      return res.status(403).json({ error: { code: 'WAREHOUSE_ACCESS_DENIED', message: 'You do not have access to this warehouse.' } });
    }

    const itemIds = input.items.map(x => x.orderItemId);
    const orderItems = await db.query(
      `SELECT oi.id,oi.product_id,oi.ordered_qty,oi.dispatched_qty,p.sku,p.name
       FROM order_items oi
       JOIN products p ON p.id=oi.product_id
       WHERE oi.order_id=$1 AND oi.id=ANY($2::uuid[])
       FOR UPDATE`,
      [orderId, itemIds],
    );
    if (orderItems.rowCount !== input.items.length) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_RETURN_ITEMS', message: 'One or more return items do not belong to the original order.' } });
    }

    const returnNo = `RET-${Date.now().toString().slice(-10)}`;
    const ret = await db.query(
      `INSERT INTO returns(company_id,client_id,order_id,invoice_id,warehouse_id,return_no,reason,status,created_by)
       VALUES($1,$2,$3,$4,$5,$6,$7,'gate_in_pending',$8)
       RETURNING *`,
      [req.tenant.companyId,order.rows[0].client_id,orderId,invoiceId,input.warehouseId,returnNo,input.reason,req.user.sub],
    );

    for (const inputItem of input.items) {
      const source = orderItems.rows.find(x => x.id === inputItem.orderItemId);
      const returnedBefore = await db.query(
        `SELECT COALESCE(SUM(ri.returned_qty),0) returned_qty
         FROM return_items ri
         JOIN returns r ON r.id=ri.return_id
         WHERE ri.order_item_id=$1 AND r.company_id=$2 AND r.status <> 'cancelled'`,
        [source.id, req.tenant.companyId],
      );
      const remaining = Number(source.dispatched_qty || 0) - Number(returnedBefore.rows[0].returned_qty || 0);
      if (inputItem.returnedQty > remaining) {
        await db.query('ROLLBACK');
        return res.status(400).json({
          error: {
            code: 'RETURN_QTY_EXCEEDS_DISPATCHED',
            message: `Return quantity for ${source.sku} exceeds the remaining dispatched quantity (${remaining}).`,
          },
        });
      }
      await db.query(
        `INSERT INTO return_items(return_id,order_item_id,product_id,returned_qty)
         VALUES($1,$2,$3,$4)`,
        [ret.rows[0].id,source.id,source.product_id,inputItem.returnedQty],
      );
    }

    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'RETURN_CREATED','return',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,ret.rows[0].id,req.ip || null,req.get('user-agent') || null,
        JSON.stringify({returnNo,orderId,invoiceId,warehouseId:input.warehouseId})],
    );

    await db.query('COMMIT');
    res.status(201).json({ return: ret.rows[0] });
  } catch (e) {
    await db.query('ROLLBACK').catch(() => {});
    if (e.name === 'ZodError') {
      return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: e.issues?.[0]?.message || 'Invalid return request.' } });
    }
    next(e);
  } finally {
    db.release();
  }
});

router.post('/:id/gate-in', requirePermission('return.manage'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const ret = await getReturn(req, req.params.id, db, true);
    if (!ret.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'RETURN_NOT_FOUND', message: 'Return not found.' } });
    }
    const current = ret.rows[0];
    if (current.status !== 'gate_in_pending') {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_RETURN_STATUS', message: 'Return is not waiting for gate-in.' } });
    }

    const updated = await db.query(
      `UPDATE returns SET status='qc_pending',gate_in_at=NOW(),gate_in_by=$2,updated_at=NOW()
       WHERE id=$1 RETURNING *`,
      [current.id,req.user.sub],
    );
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,'RETURN_GATE_IN','return',$3,$4::jsonb)`,
      [req.tenant.companyId,req.user.sub,current.id,JSON.stringify({returnNo:current.return_no})],
    );
    await db.query('COMMIT');
    res.json({ return: updated.rows[0] });
  } catch(e) {
    await db.query('ROLLBACK').catch(()=>{});
    next(e);
  } finally { db.release(); }
});

router.post('/:id/qc', requirePermission('return.manage'), async (req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=qcSchema.parse(req.body);
    await db.query('BEGIN');
    const ret=await getReturn(req,req.params.id,db,true);
    if(!ret.rowCount){await db.query('ROLLBACK');return res.status(404).json({error:{code:'RETURN_NOT_FOUND',message:'Return not found.'}});}
    const current=ret.rows[0];
    if(current.status!=='qc_pending'){await db.query('ROLLBACK');return res.status(400).json({error:{code:'RETURN_NOT_READY_FOR_QC',message:'Return must be gate-in completed before QC.'}});}

    const ids=input.items.map(x=>x.returnItemId);
    const rows=await db.query(
      `SELECT ri.*,p.sku,p.name product_name
       FROM return_items ri JOIN products p ON p.id=ri.product_id
       WHERE ri.return_id=$1 AND ri.id=ANY($2::uuid[]) FOR UPDATE`,
      [current.id,ids],
    );
    if(rows.rowCount!==input.items.length){await db.query('ROLLBACK');return res.status(400).json({error:{code:'INVALID_QC_ITEMS',message:'One or more QC items are invalid.'}});}

    for(const q of input.items){
      const item=rows.rows.find(x=>x.id===q.returnItemId);
      const accepted=Number(q.acceptedQty),damaged=Number(q.damagedQty),rejected=Number(q.rejectedQty),returned=Number(item.returned_qty);
      if(Math.abs(accepted+damaged+rejected-returned)>0.00001){
        await db.query('ROLLBACK');
        return res.status(400).json({error:{code:'QC_QTY_MISMATCH',message:`QC quantities for ${item.sku} must equal returned quantity.`}});
      }
      if(accepted>0){
        if(!q.locationId){await db.query('ROLLBACK');return res.status(400).json({error:{code:'LOCATION_REQUIRED',message:`Accepted quantity for ${item.sku} requires a storage location.`}});}
        const loc=await db.query(
          `SELECT id FROM warehouse_locations WHERE id=$1 AND warehouse_id=$2 AND is_active=TRUE`,
          [q.locationId,current.warehouse_id],
        );
        if(!loc.rowCount){await db.query('ROLLBACK');return res.status(400).json({error:{code:'INVALID_LOCATION',message:'Selected location is not active in the return warehouse.'}});}
      }

      let result='partial';
      if(accepted===returned) result='accepted';
      else if(damaged===returned) result='damaged';
      else if(rejected===returned) result='rejected';

      await db.query(
        `UPDATE return_items
         SET qc_result=$1,accepted_qty=$2,damaged_qty=$3,rejected_qty=$4,remarks=$5
         WHERE id=$6`,
        [result,accepted,damaged,rejected,q.remarks || null,item.id],
      );

      if(accepted>0){
        await db.query(
          `INSERT INTO inventory(company_id,product_id,warehouse_id,location_id,quantity,reserved_quantity)
           VALUES($1,$2,$3,$4,$5,0)
           ON CONFLICT(company_id,product_id,warehouse_id,location_id)
           DO UPDATE SET quantity=inventory.quantity+EXCLUDED.quantity,updated_at=NOW()`,
          [req.tenant.companyId,item.product_id,current.warehouse_id,q.locationId,accepted],
        );
        await db.query(
          `INSERT INTO inventory_transactions(
             company_id,product_id,warehouse_id,location_id,transaction_type,quantity,
             reference_type,reference_id,created_by
           ) VALUES($1,$2,$3,$4,'return', $5,'return',$6,$7)`,
          [req.tenant.companyId,item.product_id,current.warehouse_id,q.locationId,accepted,current.id,req.user.sub],
        );
      }
    }

    const remaining = await db.query(
      `SELECT COUNT(*)::int count FROM return_items WHERE return_id=$1 AND qc_result='pending'`,
      [current.id],
    );
    if(Number(remaining.rows[0].count)>0){
      await db.query('ROLLBACK');
      return res.status(400).json({error:{code:'QC_INCOMPLETE',message:'QC is required for every returned item.'}});
    }

    const totals=await db.query(
      `SELECT
         COALESCE(SUM(accepted_qty),0) accepted,
         COALESCE(SUM(damaged_qty),0) damaged,
         COALESCE(SUM(rejected_qty),0) rejected
       FROM return_items WHERE return_id=$1`,
      [current.id],
    );
    const t=totals.rows[0];
    const nextStatus=Number(t.accepted)>0 || Number(t.damaged)>0 ? 'completed' : 'rejected';
    const updated=await db.query(
      `UPDATE returns SET status=$1,completed_at=NOW(),updated_at=NOW() WHERE id=$2 RETURNING *`,
      [nextStatus,current.id],
    );

    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,'RETURN_QC_COMPLETED','return',$3,$4::jsonb)`,
      [req.tenant.companyId,req.user.sub,current.id,JSON.stringify({accepted:t.accepted,damaged:t.damaged,rejected:t.rejected})],
    );
    await db.query('COMMIT');
    res.json({return:updated.rows[0],inventoryAccepted:t.accepted,damaged:t.damaged,rejected:t.rejected});
  }catch(e){
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:e.issues?.[0]?.message||'Invalid QC request.'}});
    next(e);
  }finally{db.release();}
});

router.patch('/:id/status', requirePermission('return.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=statusSchema.parse(req.body);
    await db.query('BEGIN');
    const ret=await getReturn(req,req.params.id,db,true);
    if(!ret.rowCount){await db.query('ROLLBACK');return res.status(404).json({error:{code:'RETURN_NOT_FOUND',message:'Return not found.'}});}
    const current=ret.rows[0];
    if(!['requested','gate_in_pending','qc_pending'].includes(current.status)){
      await db.query('ROLLBACK');return res.status(400).json({error:{code:'RETURN_NOT_CANCELLABLE',message:'This return can no longer be cancelled.'}});
    }
    const updated=await db.query('UPDATE returns SET status=\'cancelled\',updated_at=NOW() WHERE id=$1 RETURNING *',[current.id]);
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,'RETURN_CANCELLED','return',$3,$4::jsonb)`,
      [req.tenant.companyId,req.user.sub,current.id,JSON.stringify({returnNo:current.return_no})],
    );
    await db.query('COMMIT');
    res.json({return:updated.rows[0]});
  }catch(e){
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid return status.'}});
    next(e);
  }finally{db.release();}
});

module.exports=router;
