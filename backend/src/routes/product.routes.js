const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const productSchema = z.object({
  sku: z.string().trim().min(1).max(100).regex(/^[A-Za-z0-9._/-]+$/),
  name: z.string().trim().min(2).max(250),
  description: z.string().trim().max(2000).optional().nullable(),
  hsnCode: z.string().trim().max(30).optional().nullable(),
  uom: z.string().trim().min(1).max(30),
  rate: z.coerce.number().finite().min(0).max(999999999999).optional(),
});

const productUpdateSchema = productSchema.partial();
const statusSchema = z.object({ isActive: z.boolean() });

const productSelect =
  'id, company_id, sku, name, description, hsn_code, uom, rate, is_active, created_at, updated_at';

router.get('/', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('product.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT ' + productSelect + ' FROM products WHERE company_id = $1 ORDER BY name ASC, sku ASC',
      [req.tenant.companyId],
    );
    return res.json({ products: result.rows });
  } catch (error) { return next(error); }
});

router.get('/:id', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('product.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT ' + productSelect + ' FROM products WHERE id = $1 AND company_id = $2 LIMIT 1',
      [req.params.id, req.tenant.companyId],
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: { code: 'PRODUCT_NOT_FOUND', message: 'Product not found.' } });
    }
    return res.json({ product: result.rows[0] });
  } catch (error) { return next(error); }
});

router.post('/', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('product.manage'), async (req, res, next) => {
  try {
    const input = productSchema.parse(req.body);
    const result = await pool.query(
      'INSERT INTO products (company_id, sku, name, description, hsn_code, uom, rate) ' +
      'VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING ' + productSelect,
      [req.tenant.companyId, input.sku, input.name, input.description || null, input.hsnCode || null, input.uom, input.rate ?? 0],
    );

    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'PRODUCT_CREATED', 'product', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null,
        JSON.stringify({ sku: input.sku, name: input.name })],
    );
    return res.status(201).json({ product: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid product request.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'PRODUCT_SKU_EXISTS', message: 'SKU already exists in this company.' } });
    return next(error);
  }
});

router.patch('/:id', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('product.manage'), async (req, res, next) => {
  try {
    const input = productUpdateSchema.parse(req.body);
    if (Object.keys(input).length === 0) return res.status(400).json({ error: { code: 'NO_FIELDS', message: 'At least one field is required.' } });

    const current = await pool.query(
      'SELECT id FROM products WHERE id = $1 AND company_id = $2 LIMIT 1',
      [req.params.id, req.tenant.companyId],
    );
    if (current.rowCount === 0) return res.status(404).json({ error: { code: 'PRODUCT_NOT_FOUND', message: 'Product not found.' } });

    const result = await pool.query(
      'UPDATE products SET sku = COALESCE($1, sku), name = COALESCE($2, name), ' +
      'description = CASE WHEN $3::boolean THEN $4 ELSE description END, ' +
      'hsn_code = CASE WHEN $5::boolean THEN $6 ELSE hsn_code END, ' +
      'uom = COALESCE($7, uom), rate = COALESCE($8, rate), updated_at = NOW() ' +
      'WHERE id = $9 AND company_id = $10 RETURNING ' + productSelect,
      [
        input.sku ?? null, input.name ?? null,
        input.description !== undefined, input.description ?? null,
        input.hsnCode !== undefined, input.hsnCode ?? null,
        input.uom ?? null, input.rate ?? null,
        req.params.id, req.tenant.companyId,
      ],
    );

    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'PRODUCT_UPDATED', 'product', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, req.params.id, req.ip || null, req.get('user-agent') || null,
        JSON.stringify({ changedFields: Object.keys(input) })],
    );
    return res.json({ product: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid product update.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'PRODUCT_SKU_EXISTS', message: 'SKU already exists in this company.' } });
    return next(error);
  }
});

router.patch('/:id/status', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('product.manage'), async (req, res, next) => {
  try {
    const input = statusSchema.parse(req.body);
    const current = await pool.query(
      'SELECT id, is_active FROM products WHERE id = $1 AND company_id = $2 LIMIT 1',
      [req.params.id, req.tenant.companyId],
    );
    if (current.rowCount === 0) return res.status(404).json({ error: { code: 'PRODUCT_NOT_FOUND', message: 'Product not found.' } });

    const result = await pool.query(
      'UPDATE products SET is_active = $1, updated_at = NOW() WHERE id = $2 AND company_id = $3 RETURNING ' + productSelect,
      [input.isActive, req.params.id, req.tenant.companyId],
    );

    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'PRODUCT_STATUS_CHANGED', 'product', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, req.params.id, req.ip || null, req.get('user-agent') || null,
        JSON.stringify({ isActive: input.isActive })],
    );
    return res.json({ product: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid product status.' } });
    return next(error);
  }
});

module.exports = router;
