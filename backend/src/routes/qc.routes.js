const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requireCompanyModule } = require('../middleware/company');
const { requireRole } = require('../middleware/role');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');

const qcSchema = z.object({
  sourceType: z.enum(['grn', 'production']),
  sourceItemId: z.string().uuid(),
  inspectedQty: z.number().positive(),
  acceptedQty: z.number().nonnegative(),
  rejectedQty: z.number().nonnegative(),
  result: z.enum(['approved', 'rejected', 'partial']),
  remarks: z.string().trim().max(1000).optional(),
}).superRefine((v, ctx) => {
  if (v.acceptedQty + v.rejectedQty > v.inspectedQty) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['acceptedQty'], message: 'Accepted plus rejected quantity cannot exceed inspected quantity.' });
  }
});

router.use(requireAuth, requireApprovedDevice, requireTenantContext, requireRole('admin'), requireCompanyModule('qc'));

router.get('/pending', requirePermission('qc.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      "SELECT 'grn' AS source_type, gi.id AS source_item_id, g.id AS source_id, " +
      "g.grn_no AS reference_no, p.sku, p.name, gi.received_qty AS quantity, gi.qc_status, w.name AS warehouse " +
      "FROM grn_items gi JOIN grns g ON g.id = gi.grn_id JOIN products p ON p.id = gi.product_id " +
      "LEFT JOIN warehouses w ON w.id = g.warehouse_id " +
      "WHERE g.company_id = $1 AND gi.qc_status = 'pending' " +
      "UNION ALL " +
      "SELECT 'production' AS source_type, pri.id, r.id, r.receipt_no, p.sku, p.name, pri.received_qty, pri.qc_status, w.name " +
      "FROM production_receipt_items pri JOIN production_receipts r ON r.id = pri.receipt_id JOIN products p ON p.id = pri.product_id " +
      "LEFT JOIN warehouses w ON w.id = r.warehouse_id " +
      "WHERE r.company_id = $1 AND pri.qc_status = 'pending' ORDER BY reference_no",
      [req.tenant.companyId],
    );
    return res.json({ data: result.rows });
  } catch (error) { return next(error); }
});

router.get('/', requirePermission('qc.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      "SELECT q.*, CASE WHEN q.grn_item_id IS NOT NULL THEN 'grn' ELSE 'production' END AS source_type, " +
      "COALESCE(g.grn_no, pr.receipt_no) AS reference_no, p.sku, p.name " +
      "FROM qc_records q LEFT JOIN grn_items gi ON gi.id = q.grn_item_id LEFT JOIN grns g ON g.id = gi.grn_id " +
      "LEFT JOIN production_receipt_items pri ON pri.id = q.production_receipt_item_id " +
      "LEFT JOIN production_receipts pr ON pr.id = pri.receipt_id " +
      "LEFT JOIN products p ON p.id = COALESCE(gi.product_id, pri.product_id) " +
      "WHERE q.company_id = $1 ORDER BY q.created_at DESC LIMIT 100",
      [req.tenant.companyId],
    );
    return res.json({ data: result.rows });
  } catch (error) { return next(error); }
});

router.post('/', requirePermission('qc.manage'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const input = qcSchema.parse(req.body);
    await client.query('BEGIN');

    const source = input.sourceType === 'grn'
      ? await client.query(
          "SELECT gi.id, gi.product_id, gi.received_qty, gi.qc_status, g.id AS parent_id " +
          "FROM grn_items gi JOIN grns g ON g.id = gi.grn_id WHERE gi.id = $1 AND g.company_id = $2 FOR UPDATE",
          [input.sourceItemId, req.tenant.companyId])
      : await client.query(
          "SELECT pri.id, pri.product_id, pri.received_qty, pri.qc_status, r.id AS parent_id " +
          "FROM production_receipt_items pri JOIN production_receipts r ON r.id = pri.receipt_id WHERE pri.id = $1 AND r.company_id = $2 FOR UPDATE",
          [input.sourceItemId, req.tenant.companyId]);

    if (source.rowCount === 0) {
      const error = new Error('QC source item not found.');
      error.statusCode = 404; error.code = 'QC_SOURCE_NOT_FOUND'; throw error;
    }
    const item = source.rows[0];
    if (item.qc_status !== 'pending') {
      const error = new Error('This item has already been processed by QC.');
      error.statusCode = 409; error.code = 'QC_ALREADY_PROCESSED'; throw error;
    }
    if (input.inspectedQty > Number(item.received_qty)) {
      const error = new Error('Inspected quantity cannot exceed received quantity.');
      error.statusCode = 400; error.code = 'QC_QTY_EXCEEDS_RECEIVED'; throw error;
    }

    const record = await client.query(
      "INSERT INTO qc_records (company_id, grn_item_id, production_receipt_item_id, result, inspected_qty, accepted_qty, rejected_qty, remarks, inspected_by, inspected_at) " +
      "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW()) RETURNING *",
      [
        req.tenant.companyId,
        input.sourceType === 'grn' ? input.sourceItemId : null,
        input.sourceType === 'production' ? input.sourceItemId : null,
        input.result, input.inspectedQty, input.acceptedQty,
        input.rejectedQty, input.remarks || null, req.user.sub,
      ],
    );

    const newStatus = input.result === 'approved' ? 'approved'
      : input.result === 'rejected' ? 'rejected' : 'partial';

    if (input.sourceType === 'grn') {
      await client.query('UPDATE grn_items SET qc_status = $1 WHERE id = $2', [newStatus, input.sourceItemId]);
      await client.query('UPDATE grns SET status = $1, updated_at = NOW() WHERE id = $2', [newStatus, item.parent_id]);
    } else {
      await client.query('UPDATE production_receipt_items SET qc_status = $1 WHERE id = $2', [newStatus, input.sourceItemId]);
      await client.query('UPDATE production_receipts SET status = $1, updated_at = NOW() WHERE id = $2', [newStatus, item.parent_id]);
    }

    await client.query(
      "INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, metadata) VALUES ($1, $2, 'QC_PROCESSED', 'qc_record', $3, $4::jsonb)",
      [req.tenant.companyId, req.user.sub, record.rows[0].id, JSON.stringify(input)],
    );

    await client.query('COMMIT');
    return res.status(201).json({ data: record.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid QC request.' } });
    return next(error);
  } finally { client.release(); }
});

module.exports = router;
