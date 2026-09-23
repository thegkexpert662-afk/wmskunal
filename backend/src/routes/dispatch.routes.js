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
  orderId: z.string().uuid(),
  vehicleNo: z.string().trim().max(50).optional(),
  transporterName: z.string().trim().max(200).optional(),
  driverName: z.string().trim().max(150).optional(),
  driverMobile: z.string().trim().max(30).optional(),
  lrNo: z.string().trim().max(100).optional(),
});

const statusSchema = z.object({
  status: z.enum(['in_transit', 'delivered', 'cancelled']),
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

router.get('/pending', requirePermission('dispatch.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    const scope = warehouseScope(ids, params, 'o');
    const result = await pool.query(
      `SELECT o.id order_id,o.order_no,o.required_date,o.warehouse_id,
              w.code warehouse_code,w.name warehouse_name,
              c.client_code,c.name client_name,
              p.id packing_id,p.packing_no,p.total_packages,
              COALESCE(SUM(pk.weight),0) total_weight,
              COUNT(oi.id)::int item_count,
              COALESCE(SUM(oi.ordered_qty),0) total_qty
       FROM orders o
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       JOIN packing p ON p.order_id=o.id AND p.company_id=o.company_id AND p.status='ready'
       LEFT JOIN packages pk ON pk.packing_id=p.id
       JOIN order_items oi ON oi.order_id=o.id
       LEFT JOIN dispatch d ON d.order_id=o.id
          AND d.company_id=o.company_id
          AND d.status IN ('ready','dispatched','in_transit')
       WHERE o.company_id=$1 AND o.status='packed'
         AND d.id IS NULL${scope}
       GROUP BY o.id,w.code,w.name,c.id,c.client_code,c.name,p.id,p.packing_no,p.total_packages
       ORDER BY o.required_date NULLS LAST,o.created_at
       LIMIT 200`,
      params,
    );
    res.json({ orders: result.rows });
  } catch (e) {
    next(e);
  }
});

router.get('/', requirePermission('dispatch.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    let scope = warehouseScope(ids, params, 'o');
    if (req.query.status) {
      params.push(String(req.query.status));
      scope += ` AND d.status=$${params.length}`;
    }
    const result = await pool.query(
      `SELECT d.*,o.order_no,o.status order_status,
              w.code warehouse_code,w.name warehouse_name,
              c.name client_name,
              u.full_name created_by_name
       FROM dispatch d
       JOIN orders o ON o.id=d.order_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       LEFT JOIN users u ON u.id=d.created_by
       WHERE d.company_id=$1${scope}
       ORDER BY d.created_at DESC
       LIMIT 300`,
      params,
    );
    res.json({ dispatches: result.rows });
  } catch (e) {
    next(e);
  }
});

router.get('/:id', requirePermission('dispatch.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.params.id, req.tenant.companyId];
    const scope = warehouseScope(ids, params, 'o');
    const result = await pool.query(
      `SELECT d.*,o.order_no,o.status order_status,o.required_date,o.remarks,
              o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
              c.client_code,c.name client_name,
              o.sold_by_name,o.sold_by_address,o.sold_to_name,o.sold_to_address,
              o.ship_to_name,o.ship_to_address
       FROM dispatch d
       JOIN orders o ON o.id=d.order_id
       JOIN warehouses w ON w.id=o.warehouse_id
       JOIN clients c ON c.id=o.client_id
       WHERE d.id=$1 AND d.company_id=$2${scope}
       LIMIT 1`,
      params,
    );
    if (!result.rowCount) {
      return res.status(404).json({ error: { code: 'DISPATCH_NOT_FOUND', message: 'Dispatch not found.' } });
    }
    const items = await pool.query(
      `SELECT di.*,oi.product_id,p.sku,p.name product_name,p.uom
       FROM dispatch_items di
       JOIN order_items oi ON oi.id=di.order_item_id
       JOIN products p ON p.id=oi.product_id
       WHERE di.dispatch_id=$1
       ORDER BY p.name`,
      [req.params.id],
    );
    res.json({ dispatch: { ...result.rows[0], items: items.rows } });
  } catch (e) {
    next(e);
  }
});

router.post('/', requirePermission('dispatch.manage'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = createSchema.parse(req.body);
    await db.query('BEGIN');

    const orderResult = await accessibleOrder(req, input.orderId, db, true);
    if (!orderResult.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'ORDER_NOT_FOUND', message: 'Order not found or outside warehouse access.' } });
    }

    const order = orderResult.rows[0];
    if (order.status !== 'packed') {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'ORDER_NOT_READY_FOR_DISPATCH', message: 'Only packed orders can be dispatched.' } });
    }

    const packing = await db.query(
      `SELECT p.*,COALESCE(SUM(pk.weight),0) total_weight
       FROM packing p
       LEFT JOIN packages pk ON pk.packing_id=p.id
       WHERE p.id=(SELECT id FROM packing WHERE order_id=$1 AND company_id=$2 AND status='ready' LIMIT 1)
       GROUP BY p.id`,
      [input.orderId, req.tenant.companyId],
    );
    if (!packing.rowCount) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'PACKING_NOT_READY', message: 'Packing must be completed before dispatch.' } });
    }

    const active = await db.query(
      `SELECT id FROM dispatch WHERE order_id=$1 AND company_id=$2
       AND status IN ('ready','dispatched','in_transit') LIMIT 1 FOR UPDATE`,
      [input.orderId, req.tenant.companyId],
    );
    if (active.rowCount) {
      await db.query('ROLLBACK');
      return res.status(409).json({ error: { code: 'ACTIVE_DISPATCH_EXISTS', message: 'An active dispatch already exists for this order.', dispatchId: active.rows[0].id } });
    }

    const dispatchNo = `DSP-${Date.now().toString().slice(-10)}`;
    const p = packing.rows[0];
    const dispatch = await db.query(
      `INSERT INTO dispatch(
         company_id,order_id,packing_id,warehouse_id,dispatch_no,
         vehicle_no,transporter_name,driver_name,driver_mobile,lr_no,
         status,total_packages,total_weight,created_by
       )
       VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'ready',$11,$12,$13)
       RETURNING *`,
      [
        req.tenant.companyId,input.orderId,p.id,order.warehouse_id,dispatchNo,
        input.vehicleNo || order.vehicle_no || null,
        input.transporterName || order.transporter_name || null,
        input.driverName || order.driver_name || null,
        input.driverMobile || order.driver_mobile || null,
        input.lrNo || null,
        Number(p.total_packages || 0),Number(p.total_weight || 0),req.user.sub,
      ],
    );

    const items = await db.query(
      'SELECT id,ordered_qty FROM order_items WHERE order_id=$1 FOR UPDATE',
      [input.orderId],
    );
    for (const item of items.rows) {
      await db.query(
        'INSERT INTO dispatch_items(dispatch_id,order_item_id,quantity) VALUES($1,$2,$3)',
        [dispatch.rows[0].id,item.id,item.ordered_qty],
      );
    }

    // Every new dispatch gets a permanent invoice record in the same transaction.
    const invoiceItems = await db.query(
      `SELECT oi.product_id,oi.ordered_qty quantity,p.name product_name,p.hsn_code,p.uom,p.rate
       FROM order_items oi
       JOIN products p ON p.id=oi.product_id
       WHERE oi.order_id=$1
       ORDER BY p.name`,
      [input.orderId],
    );
    let taxableAmount = 0;
    for (const item of invoiceItems.rows) {
      taxableAmount += Number(item.quantity || 0) * Number(item.rate || 0);
    }
    taxableAmount = Number(taxableAmount.toFixed(2));
    const invoiceNo = `INV-${new Date().getFullYear()}-${Date.now().toString().slice(-8)}`;
    const invoiceResult = await db.query(
      `INSERT INTO invoices(
         company_id,client_id,order_id,dispatch_id,invoice_no,invoice_date,status,
         taxable_amount,total_amount,
         company_name_snapshot,company_logo_url_snapshot,company_address_snapshot,company_gstin_snapshot,company_email_snapshot,company_mobile_snapshot,
         client_name_snapshot,client_address_snapshot,client_gstin_snapshot,client_email_snapshot,client_mobile_snapshot,
         created_by,updated_at
       )
       SELECT $1,o.client_id,o.id,$2,$3,CURRENT_DATE,'issued',$4,$4,
              co.name,co.logo_url,co.address,co.gstin,co.email,co.mobile,
              cl.name,cl.address,cl.gstin,cl.email,cl.mobile,
              $5,NOW()
       FROM orders o
       JOIN companies co ON co.id=o.company_id
       JOIN clients cl ON cl.id=o.client_id
       WHERE o.id=$6 AND o.company_id=$1
       RETURNING *`,
      [req.tenant.companyId,dispatch.rows[0].id,invoiceNo,taxableAmount,req.user.sub,input.orderId],
    );
    const invoice = invoiceResult.rows[0];

    for (const item of invoiceItems.rows) {
      const lineTotal = Number(item.quantity || 0) * Number(item.rate || 0);
      await db.query(
        `INSERT INTO invoice_items(
          invoice_id,product_id,description,hsn_code,uom,quantity,rate,taxable_amount,line_total
        ) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$8)`,
        [invoice.id,item.product_id,item.product_name,item.hsn_code,item.uom,item.quantity,item.rate || 0,lineTotal],
      );
    }

    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'DISPATCH_CREATED','dispatch',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,dispatch.rows[0].id,req.ip || null,req.get('user-agent') || null,
        JSON.stringify({orderId:input.orderId,orderNo:order.order_no,warehouseId:order.warehouse_id,invoiceId:invoice.id,invoiceNo:invoice.invoice_no})],
    );

    await db.query('COMMIT');
    res.status(201).json({ dispatch: dispatch.rows[0], invoice });
  } catch (e) {
    await db.query('ROLLBACK').catch(() => {});
    if (e.name === 'ZodError') {
      return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid dispatch request.' } });
    }
    if (e.code === '23505') {
      return res.status(409).json({ error: { code: 'ACTIVE_DISPATCH_EXISTS', message: 'An active dispatch already exists.' } });
    }
    next(e);
  } finally {
    db.release();
  }
});

router.post('/:id/gate-out', requirePermission('dispatch.manage'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const ids = await assigned(req);
    const params = [req.params.id,req.tenant.companyId];
    const scope = warehouseScope(ids,params,'o');
    const result = await db.query(
      `SELECT d.*,o.order_no,o.status order_status,o.warehouse_id
       FROM dispatch d JOIN orders o ON o.id=d.order_id
       WHERE d.id=$1 AND d.company_id=$2${scope}
       FOR UPDATE OF d,o`,
      params,
    );
    if (!result.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'DISPATCH_NOT_FOUND', message: 'Dispatch not found.' } });
    }
    const dispatch = result.rows[0];
    if (dispatch.status !== 'ready' || dispatch.order_status !== 'packed') {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'DISPATCH_NOT_READY', message: 'Dispatch must be ready and order must be packed.' } });
    }

    const dispatchItems = await db.query(
      `SELECT di.order_item_id,di.quantity,oi.ordered_qty,oi.dispatched_qty
       FROM dispatch_items di
       JOIN order_items oi ON oi.id=di.order_item_id
       WHERE di.dispatch_id=$1
       FOR UPDATE OF oi`,
      [dispatch.id],
    );

    for (const item of dispatchItems.rows) {
      const nextDispatched = Number(item.dispatched_qty || 0) + Number(item.quantity || 0);
      if (nextDispatched > Number(item.ordered_qty || 0)) {
        await db.query('ROLLBACK');
        return res.status(400).json({
          error: { code: 'DISPATCH_QTY_EXCEEDS_ORDER', message: 'Dispatch quantity exceeds the order quantity.' },
        });
      }
      await db.query(
        `UPDATE order_items SET dispatched_qty=$1 WHERE id=$2`,
        [nextDispatched, item.order_item_id],
      );
    }

    const updated = await db.query(
      `UPDATE dispatch SET status='dispatched',dispatched_at=NOW(),updated_at=NOW()
       WHERE id=$1 RETURNING *`,
      [dispatch.id],
    );
    await db.query(
      `UPDATE orders SET status='dispatched',updated_at=NOW()
       WHERE id=$1 AND company_id=$2`,
      [dispatch.order_id,req.tenant.companyId],
    );
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'DISPATCH_GATE_OUT','dispatch',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,dispatch.id,req.ip || null,req.get('user-agent') || null,
        JSON.stringify({orderId:dispatch.order_id,orderNo:dispatch.order_no,warehouseId:dispatch.warehouse_id})],
    );
    await db.query('COMMIT');
    res.json({ dispatch: updated.rows[0], orderStatus:'dispatched' });
  } catch(e) {
    await db.query('ROLLBACK').catch(()=>{});
    next(e);
  } finally {
    db.release();
  }
});

router.patch('/:id/status', requirePermission('dispatch.manage'), async (req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=statusSchema.parse(req.body);
    await db.query('BEGIN');
    const ids=await assigned(req);
    const params=[req.params.id,req.tenant.companyId];
    const scope=warehouseScope(ids,params,'o');
    const result=await db.query(
      `SELECT d.*,o.order_no,o.status order_status,o.warehouse_id
       FROM dispatch d JOIN orders o ON o.id=d.order_id
       WHERE d.id=$1 AND d.company_id=$2${scope}
       FOR UPDATE OF d,o`,params);
    if(!result.rowCount){await db.query('ROLLBACK');return res.status(404).json({error:{code:'DISPATCH_NOT_FOUND',message:'Dispatch not found.'}});}
    const d=result.rows[0];
    const valid=(d.status==='dispatched'&&input.status==='in_transit')||(d.status==='in_transit'&&input.status==='delivered')||(d.status==='ready'&&input.status==='cancelled');
    if(!valid){await db.query('ROLLBACK');return res.status(400).json({error:{code:'INVALID_DISPATCH_STATUS',message:`Cannot change dispatch from ${d.status} to ${input.status}.`}});}
    const updated=await db.query(
      `UPDATE dispatch SET status=$1,delivered_at=CASE WHEN $1='delivered' THEN NOW() ELSE delivered_at END,updated_at=NOW()
       WHERE id=$2 RETURNING *`,[input.status,d.id]);
    if(input.status==='delivered'){
      await db.query(`UPDATE orders SET status='delivered',updated_at=NOW() WHERE id=$1 AND company_id=$2`,[d.order_id,req.tenant.companyId]);
    }
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,$3,'dispatch',$4,$5,$6,$7::jsonb)`,
      [req.tenant.companyId,req.user.sub,`DISPATCH_STATUS_${input.status.toUpperCase()}`,d.id,req.ip||null,req.get('user-agent')||null,JSON.stringify({orderId:d.order_id,from:d.status,to:input.status})]);
    await db.query('COMMIT');
    res.json({dispatch:updated.rows[0]});
  }catch(e){
    await db.query('ROLLBACK').catch(()=>{});
    if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid dispatch status.'}});
    next(e);
  }finally{db.release();}
});

module.exports=router;
