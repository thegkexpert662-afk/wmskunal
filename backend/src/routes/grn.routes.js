const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requireCompanyModule } = require('../middleware/company');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

const grnSchema = z.object({
  grnNo: z.string().trim().min(1).max(60),
  supplierName: z.string().trim().max(200).optional(),
  invoiceNo: z.string().trim().max(100).optional(),
  warehouseId: z.string().uuid().optional(),
  receivedAt: z.string().datetime().optional(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    receivedQty: z.number().positive(),
  })).min(1),
});

router.use(requireAuth, requireApprovedDevice, requireTenantContext, requireCompanyModule('grn'));

router.get('/', requirePermission('grn.read'), async (req, res, next) => {
  try {
    const assigned = await getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
    const params = [req.tenant.companyId];
    let warehouseScope = '';
    if (assigned.length) { params.push(assigned); warehouseScope = ' AND g.warehouse_id = ANY($2::uuid[])'; }
    const result = await pool.query(
      `SELECT g.id, g.grn_no, g.supplier_name, g.invoice_no, g.status,
              g.received_at, g.created_at, w.name AS warehouse
       FROM grns g
       LEFT JOIN warehouses w ON w.id = g.warehouse_id
       WHERE g.company_id = $1 ${warehouseScope}
       ORDER BY g.created_at DESC
       LIMIT 100`,
      params,
    );
    return res.json({ data: result.rows });
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', requirePermission('grn.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT g.*, w.name AS warehouse
       FROM grns g
       LEFT JOIN warehouses w ON w.id = g.warehouse_id
       WHERE g.id = $1 AND g.company_id = $2
         AND ($3::uuid[] IS NULL OR g.warehouse_id = ANY($3::uuid[]))`,
      [req.params.id, req.tenant.companyId, assigned.length ? assigned : null],
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        error: { code: 'GRN_NOT_FOUND', message: 'GRN not found.' },
      });
    }

    const items = await pool.query(
      `SELECT gi.id, gi.product_id, p.sku, p.name, gi.received_qty, gi.qc_status
       FROM grn_items gi
       JOIN products p ON p.id = gi.product_id
       JOIN grns g ON g.id = gi.grn_id
       WHERE gi.grn_id = $1 AND g.company_id = $2
       ORDER BY gi.created_at`,
      [req.params.id, req.tenant.companyId],
    );

    return res.json({ data: { ...result.rows[0], items: items.rows } });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requirePermission('grn.create'), async (req, res, next) => {
  const client = await pool.connect();

  try {
    const input = grnSchema.parse(req.body);
    const assigned = await getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
    if (assigned.length && (!input.warehouseId || !assigned.includes(input.warehouseId))) {
      return res.status(403).json({ error: { code: 'WAREHOUSE_ACCESS_DENIED', message: 'You must be assigned to the selected warehouse.' } });
    }

    await client.query('BEGIN');

    if (input.warehouseId) {
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
    }

    const grn = await client.query(
      `INSERT INTO grns
        (company_id, grn_no, supplier_name, invoice_no, warehouse_id, received_at, status, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, 'received', $7)
       RETURNING id, grn_no, status, created_at`,
      [
        req.tenant.companyId,
        input.grnNo,
        input.supplierName || null,
        input.invoiceNo || null,
        input.warehouseId || null,
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
        `INSERT INTO grn_items (grn_id, product_id, received_qty)
         VALUES ($1, $2, $3)`,
        [grn.rows[0].id, item.productId, item.receivedQty],
      );
    }

    await client.query(
      `INSERT INTO audit_logs
        (company_id, user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, $2, 'CREATE_GRN', 'grn', $3, $4::jsonb)`,
      [
        req.tenant.companyId,
        req.user.sub,
        grn.rows[0].id,
        JSON.stringify({ grnNo: input.grnNo, itemCount: input.items.length }),
      ],
    );

    await client.query('COMMIT');

    return res.status(201).json({ data: grn.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.name === 'ZodError') {
      return res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Invalid GRN request.' },
      });
    }
    if (error.code === '23505') {
      return res.status(409).json({
        error: { code: 'GRN_ALREADY_EXISTS', message: 'GRN number already exists for this company.' },
      });
    }
    return next(error);
  } finally {
    client.release();
  }
});

module.exports = router;
