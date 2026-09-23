const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requireTenantContext } = require('../middleware/tenant');
const { requirePermission } = require('../middleware/permission');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

const createSchema = z.object({
  orderNo: z.string().trim().min(1).max(60),
  clientId: z.string().uuid().optional(),
  warehouseId: z.string().uuid(),
  requiredDate: z.string().date().optional(),
  remarks: z.string().trim().max(1000).optional(),
  truckType: z.string().trim().max(100).optional(),
  transporterName: z.string().trim().max(200).optional(),
  vehicleNo: z.string().trim().max(60).optional(),
  driverName: z.string().trim().max(150).optional(),
  driverMobile: z.string().trim().max(30).optional(),
  shipmentNo: z.string().trim().max(100).optional(),
  shipmentDate: z.string().date().optional(),
  deliveryNo: z.string().trim().max(100).optional(),
  deliveryDate: z.string().date().optional(),
  soldByName: z.string().trim().max(200).optional(),
  soldByAddress: z.string().trim().max(2000).optional(),
  soldByGstin: z.string().trim().max(20).optional(),
  soldToName: z.string().trim().max(200).optional(),
  soldToAddress: z.string().trim().max(2000).optional(),
  soldToGstin: z.string().trim().max(20).optional(),
  shipToName: z.string().trim().max(200).optional(),
  shipToAddress: z.string().trim().max(2000).optional(),
  shipToGstin: z.string().trim().max(20).optional(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    orderedQty: z.coerce.number().positive(),
  })).min(1),
}).superRefine((v, ctx) => {
  const seen = new Set();
  v.items.forEach((item, i) => {
    if (seen.has(item.productId)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['items', i, 'productId'],
        message: 'Duplicate product is not allowed in the same order.',
      });
    }
    seen.add(item.productId);
  });
});

const statusSchema = z.object({ status: z.string().trim().min(1).max(30) });

const allowedTransitions = {
  draft: ['confirmed', 'cancelled'],
  confirmed: ['allocated', 'cancelled'],
  allocated: ['picking', 'cancelled'],
  picking: ['packed'],
  packed: ['dispatched'],
  dispatched: ['delivered'],
  delivered: [],
  cancelled: [],
};

async function assigned(req) {
  return getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
}

function denied(ids, warehouseId) {
  return ids.length > 0 && !ids.includes(warehouseId);
}

async function accessibleOrder(req, id, db = pool) {
  const ids = await assigned(req);
  const params = [id, req.tenant.companyId];
  let scope = '';
  if (ids.length) {
    params.push(ids);
    scope = ' AND o.warehouse_id = ANY($3::uuid[])';
  }
  const result = await db.query(
    `SELECT o.*, c.client_code, c.name client_name,
            w.code warehouse_code, w.name warehouse_name,
            u.full_name created_by_name
     FROM orders o
     JOIN clients c ON c.id = o.client_id
     JOIN warehouses w ON w.id = o.warehouse_id
     LEFT JOIN users u ON u.id = o.created_by
     WHERE o.id = $1 AND o.company_id = $2${scope}
     LIMIT 1`,
    params,
  );
  return result;
}

router.get('/', requirePermission('order.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    const filters = ['o.company_id = $1'];

    if (ids.length) {
      params.push(ids);
      filters.push('o.warehouse_id = ANY($2::uuid[])');
    }

    if (req.user.role === 'client') {
      params.push(req.tenant.clientId);
      filters.push(`o.client_id = $${params.length}`);
    }

    if (req.query.status) {
      params.push(req.query.status);
      filters.push(`o.status = $${params.length}`);
    }

    if (req.query.search) {
      params.push(`%${String(req.query.search).trim()}%`);
      filters.push(`(o.order_no ILIKE $${params.length} OR c.name ILIKE $${params.length} OR c.client_code ILIKE $${params.length})`);
    }

    const result = await pool.query(
      `SELECT o.id, o.order_no, o.status, o.required_date, o.created_at,
              o.warehouse_id, w.code warehouse_code, w.name warehouse_name,
              c.id client_id, c.client_code, c.name client_name,
              COUNT(oi.id)::int item_count,
              COALESCE(SUM(oi.ordered_qty), 0) total_qty,
              COALESCE(SUM(oi.ordered_qty * COALESCE(p.rate, 0)), 0) order_value
       FROM orders o
       JOIN clients c ON c.id = o.client_id
       JOIN warehouses w ON w.id = o.warehouse_id
       LEFT JOIN order_items oi ON oi.order_id = o.id
       LEFT JOIN products p ON p.id = oi.product_id
       WHERE ${filters.join(' AND ')}
       GROUP BY o.id, w.code, w.name, c.id, c.client_code, c.name
       ORDER BY o.created_at DESC
       LIMIT 200`,
      params,
    );
    return res.json({ orders: result.rows });
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', requirePermission('order.read'), async (req, res, next) => {
  try {
    const result = await accessibleOrder(req, req.params.id);
    if (!result.rowCount) {
      return res.status(404).json({ error: { code: 'ORDER_NOT_FOUND', message: 'Order not found.' } });
    }

    if (req.user.role === 'client' && result.rows[0].client_id !== req.tenant.clientId) {
      return res.status(403).json({ error: { code: 'CLIENT_ACCESS_DENIED', message: 'You can only access your own orders.' } });
    }

    const items = await pool.query(
      `SELECT oi.*, p.sku, p.name product_name, p.uom, p.rate
       FROM order_items oi
       JOIN products p ON p.id = oi.product_id
       WHERE oi.order_id = $1
       ORDER BY p.name`,
      [req.params.id],
    );

    return res.json({ order: { ...result.rows[0], items: items.rows } });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requirePermission('order.create'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = createSchema.parse(req.body);
    const clientId = req.user.role === 'client' ? req.tenant.clientId : input.clientId;

    if (!clientId) {
      return res.status(400).json({ error: { code: 'CLIENT_REQUIRED', message: 'Client is required.' } });
    }

    const ids = await assigned(req);
    if (denied(ids, input.warehouseId)) {
      return res.status(403).json({ error: { code: 'WAREHOUSE_ACCESS_DENIED', message: 'You are not assigned to this warehouse.' } });
    }

    await db.query('BEGIN');

    const client = await db.query(
      'SELECT id FROM clients WHERE id = $1 AND company_id = $2 AND is_active = TRUE',
      [clientId, req.tenant.companyId],
    );
    if (!client.rowCount) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_CLIENT', message: 'Client is invalid or inactive.' } });
    }

    const warehouse = await db.query(
      'SELECT id FROM warehouses WHERE id = $1 AND company_id = $2 AND is_active = TRUE',
      [input.warehouseId, req.tenant.companyId],
    );
    if (!warehouse.rowCount) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_WAREHOUSE', message: 'Warehouse is invalid or inactive.' } });
    }

    const order = await db.query(
      `INSERT INTO orders(
         company_id, client_id, warehouse_id, order_no, status, required_date, remarks, created_by,
         truck_type, transporter_name, vehicle_no, driver_name, driver_mobile,
         shipment_no, shipment_date, delivery_no, delivery_date,
         sold_by_name, sold_by_address, sold_by_gstin,
         sold_to_name, sold_to_address, sold_to_gstin,
         ship_to_name, ship_to_address, ship_to_gstin
       )
       VALUES(
         $1, $2, $3, $4, 'draft', $5, $6, $7,
         $8, $9, $10, $11, $12, $13, $14, $15, $16,
         $17, $18, $19, $20, $21, $22, $23, $24, $25
       )
       RETURNING *`,
      [req.tenant.companyId, clientId, input.warehouseId, input.orderNo, input.requiredDate || null, input.remarks || null, req.user.sub,
       input.truckType || null, input.transporterName || null, input.vehicleNo || null, input.driverName || null, input.driverMobile || null,
       input.shipmentNo || null, input.shipmentDate || null, input.deliveryNo || null, input.deliveryDate || null,
       input.soldByName || null, input.soldByAddress || null, input.soldByGstin || null,
       input.soldToName || null, input.soldToAddress || null, input.soldToGstin || null,
       input.shipToName || null, input.shipToAddress || null, input.shipToGstin || null],
    );

    for (const item of input.items) {
      const product = await db.query(
        'SELECT id FROM products WHERE id = $1 AND company_id = $2 AND is_active = TRUE',
        [item.productId, req.tenant.companyId],
      );
      if (!product.rowCount) {
        const error = new Error('Product is invalid or inactive.');
        error.statusCode = 400;
        error.code = 'INVALID_PRODUCT';
        throw error;
      }

      await db.query(
        'INSERT INTO order_items(order_id, product_id, ordered_qty) VALUES($1, $2, $3)',
        [order.rows[0].id, item.productId, item.orderedQty],
      );
    }

    await db.query(
      `INSERT INTO audit_logs(company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
       VALUES($1, $2, 'ORDER_CREATED', 'order', $3, $4, $5, $6::jsonb)`,
      [req.tenant.companyId, req.user.sub, order.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ orderNo: input.orderNo, itemCount: input.items.length })],
    );

    await db.query('COMMIT');
    return res.status(201).json({ order: order.rows[0] });
  } catch (error) {
    await db.query('ROLLBACK').catch(() => {});
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid order request.' } });
    }
    if (error.code === '23505') {
      return res.status(409).json({ error: { code: 'ORDER_ALREADY_EXISTS', message: 'Order number already exists for this company.' } });
    }
    return next(error);
  } finally {
    db.release();
  }
});

router.patch('/:id/status', requirePermission('order.manage'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = statusSchema.parse(req.body);
    await db.query('BEGIN');

    const result = await accessibleOrder(req, req.params.id, db);
    if (!result.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'ORDER_NOT_FOUND', message: 'Order not found.' } });
    }

    const order = result.rows[0];
    const next = input.status;
    if (!Object.prototype.hasOwnProperty.call(allowedTransitions, order.status) || !allowedTransitions[order.status].includes(next)) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_STATUS_TRANSITION', message: `Cannot change order from ${order.status} to ${next}.` } });
    }

    const updated = await db.query(
      'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 AND company_id = $3 RETURNING *',
      [next, req.params.id, req.tenant.companyId],
    );

    await db.query(
      `INSERT INTO audit_logs(company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
       VALUES($1, $2, $3, 'order', $4, $5, $6, $7::jsonb)`,
      [req.tenant.companyId, req.user.sub, `ORDER_STATUS_${next.toUpperCase()}`, req.params.id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ from: order.status, to: next })],
    );

    await db.query('COMMIT');
    return res.json({ order: updated.rows[0] });
  } catch (error) {
    await db.query('ROLLBACK').catch(() => {});
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid order status.' } });
    }
    return next(error);
  } finally {
    db.release();
  }
});

module.exports = router;
