const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requireCompanyModule } = require('../middleware/company');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');

const receiptSchema = z.object({
  receiptNo: z.string().trim().min(1).max(60),
  productionReference: z.string().trim().max(100).optional(),
  warehouseId: z.string().uuid(),
  receivedAt: z.string().datetime().optional(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    receivedQty: z.number().positive(),
  })).min(1),
});

router.use(
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requireCompanyModule('inbound'),
);

router.get('/', requirePermission('inbound.read'), async (req, res, next) => {
  try {
    const ids = await getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
    const params = [req.tenant.companyId];
    let warehouseFilter = '';
    if (ids.length) { params.push(ids); warehouseFilter = ' AND r.warehouse_id = ANY($2::uuid[])'; }
    const result = await pool.query(
      `SELECT r.id, r.receipt_no, r.production_reference, r.status,
              r.received_at, r.created_at, w.name AS warehouse
       FROM production_receipts r
       LEFT JOIN warehouses w ON w.id = r.warehouse_id
       WHERE r.company_id = $1 ${warehouseFilter}
       ORDER BY r.created_at DESC
       LIMIT 100`,
      params,
    );
    return res.json({ data: result.rows });
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', requirePermission('inbound.read'), async (req, res, next) => {
  try {
    const ids = await getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
    const receipt = await pool.query(
      `SELECT r.*, w.name AS warehouse
       FROM production_receipts r
       LEFT JOIN warehouses w ON w.id = r.warehouse_id
       WHERE r.id = $1 AND r.company_id = $2`,
      [req.params.id, req.tenant.companyId],
    );
    if (receipt.rowCount === 0) {
      return res.status(404).json({
        error: { code: 'PRODUCTION_RECEIPT_NOT_FOUND', message: 'Production receipt not found.' },
      });
    }

    if (ids.length && !ids.includes(receipt.rows[0].warehouse_id)) {
      return res.status(403).json({ error: { code: 'WAREHOUSE_ACCESS_DENIED', message: 'You are not assigned to this warehouse.' } });
    }

    const items = await pool.query(
      `SELECT pri.id, pri.product_id, p.sku, p.name,
              pri.received_qty, pri.qc_status
       FROM production_receipt_items pri
       JOIN products p ON p.id = pri.product_id
       JOIN production_receipts r ON r.id = pri.receipt_id
       WHERE pri.receipt_id = $1 AND r.company_id = $2
       ORDER BY pri.created_at`,
      [req.params.id, req.tenant.companyId],
    );

    return res.json({ data: { ...receipt.rows[0], items: items.rows } });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requirePermission('inbound.create'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const input = receiptSchema.parse(req.body);
    const ids = await getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
    if (ids.length && !ids.includes(input.warehouseId)) {
      return res.status(403).json({ error: { code: 'WAREHOUSE_ACCESS_DENIED', message: 'You are not assigned to this warehouse.' } });
    }
    await client.query('BEGIN');

    const warehouse = await client.query(
      'SELECT id FROM warehouses WHERE id = $1 AND company_id = $2 AND is_active = TRUE',
      [input.warehouseId, req.tenant.companyId],
    );
    if (warehouse.rowCount === 0) {
      const error = new Error('Warehouse does not belong to this company.');
      error.statusCode = 400;
      error.code = 'INVALID_WAREHOUSE';
      throw error;
    }

    const receipt = await client.query(
      `INSERT INTO production_receipts
        (company_id, receipt_no, production_reference, warehouse_id, received_at, status, created_by)
       VALUES ($1, $2, $3, $4, $5, 'received', $6)
       RETURNING id, receipt_no, status, created_at`,
      [
        req.tenant.companyId,
        input.receiptNo,
        input.productionReference || null,
        input.warehouseId,
        input.receivedAt ? new Date(input.receivedAt) : new Date(),
        req.user.sub,
      ],
    );

    for (const item of input.items) {
      const product = await client.query(
        'SELECT id FROM products WHERE id = $1 AND company_id = $2 AND is_active = TRUE',
        [item.productId, req.tenant.companyId],
      );
      if (product.rowCount === 0) {
        const error = new Error('Product does not belong to this company.');
        error.statusCode = 400;
        error.code = 'INVALID_PRODUCT';
        throw error;
      }

      await client.query(
        `INSERT INTO production_receipt_items
          (receipt_id, product_id, received_qty)
         VALUES ($1, $2, $3)`,
        [receipt.rows[0].id, item.productId, item.receivedQty],
      );
    }

    await client.query(
      `INSERT INTO audit_logs
        (company_id, user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, $2, 'CREATE_PRODUCTION_RECEIPT', 'production_receipt', $3, $4::jsonb)`,
      [
        req.tenant.companyId,
        req.user.sub,
        receipt.rows[0].id,
        JSON.stringify({ receiptNo: input.receiptNo, itemCount: input.items.length }),
      ],
    );

    await client.query('COMMIT');
    return res.status(201).json({ data: receipt.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.name === 'ZodError') {
      return res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Invalid production receipt request.' },
      });
    }
    if (error.code === '23505') {
      return res.status(409).json({
        error: { code: 'RECEIPT_ALREADY_EXISTS', message: 'Receipt number already exists for this company.' },
      });
    }
    return next(error);
  } finally {
    client.release();
  }
});

module.exports = router;
