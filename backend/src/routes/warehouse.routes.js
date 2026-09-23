const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const warehouseSchema = z.object({
  code: z.string().trim().min(2).max(50).regex(/^[A-Za-z0-9._-]+$/),
  name: z.string().trim().min(2).max(150),
  address: z.string().trim().max(1000).optional().nullable(),
});
const warehouseUpdateSchema = warehouseSchema.partial();
const locationSchema = z.object({
  code: z.string().trim().min(1).max(80).regex(/^[A-Za-z0-9._/-]+$/),
  zone: z.string().trim().max(80).optional().nullable(),
  bin: z.string().trim().max(80).optional().nullable(),
});
const locationUpdateSchema = locationSchema.partial();
const statusSchema = z.object({ isActive: z.boolean() });

async function getWarehouse(warehouseId, companyId) {
  const result = await pool.query(
    'SELECT id, company_id, code, name, address, is_active, created_at, updated_at ' +
    'FROM warehouses WHERE id = $1 AND company_id = $2 LIMIT 1',
    [warehouseId, companyId],
  );
  return result.rows[0] || null;
}

router.get('/', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT w.id, w.code, w.name, w.address, w.is_active, w.created_at, w.updated_at, ' +
      'COUNT(l.id)::int AS location_count, COUNT(l.id) FILTER (WHERE l.is_active = TRUE)::int AS active_location_count ' +
      'FROM warehouses w LEFT JOIN warehouse_locations l ON l.warehouse_id = w.id ' +
      'WHERE w.company_id = $1 GROUP BY w.id ORDER BY w.name ASC',
      [req.tenant.companyId],
    );
    return res.json({ warehouses: result.rows });
  } catch (error) { return next(error); }
});

router.get('/:id', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.read'), async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT w.id, w.code, w.name, w.address, w.is_active, w.created_at, w.updated_at, ' +
      'COUNT(l.id)::int AS location_count, COUNT(l.id) FILTER (WHERE l.is_active = TRUE)::int AS active_location_count ' +
      'FROM warehouses w LEFT JOIN warehouse_locations l ON l.warehouse_id = w.id ' +
      'WHERE w.id = $1 AND w.company_id = $2 GROUP BY w.id',
      [req.params.id, req.tenant.companyId],
    );
    if (result.rowCount === 0) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });
    return res.json({ warehouse: result.rows[0] });
  } catch (error) { return next(error); }
});

router.post('/', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = warehouseSchema.parse(req.body);
    const result = await pool.query(
      'INSERT INTO warehouses (company_id, code, name, address) VALUES ($1, $2, $3, $4) ' +
      'RETURNING id, company_id, code, name, address, is_active, created_at, updated_at',
      [req.tenant.companyId, input.code, input.name, input.address || null],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'WAREHOUSE_CREATED', 'warehouse', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ code: input.code })],
    );
    return res.status(201).json({ warehouse: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid warehouse request.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'WAREHOUSE_CODE_EXISTS', message: 'Warehouse code already exists in this company.' } });
    return next(error);
  }
});

router.patch('/:id', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = warehouseUpdateSchema.parse(req.body);
    if (Object.keys(input).length === 0) return res.status(400).json({ error: { code: 'NO_FIELDS', message: 'At least one field is required.' } });
    const existing = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!existing) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });

    const result = await pool.query(
      'UPDATE warehouses SET code = COALESCE($1, code), name = COALESCE($2, name), ' +
      'address = CASE WHEN $3::boolean THEN $4 ELSE address END, updated_at = NOW() ' +
      'WHERE id = $5 AND company_id = $6 ' +
      'RETURNING id, company_id, code, name, address, is_active, created_at, updated_at',
      [input.code ?? null, input.name ?? null, input.address !== undefined, input.address ?? null, existing.id, req.tenant.companyId],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'WAREHOUSE_UPDATED', 'warehouse', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, existing.id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ changedFields: Object.keys(input) })],
    );
    return res.json({ warehouse: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid warehouse update.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'WAREHOUSE_CODE_EXISTS', message: 'Warehouse code already exists in this company.' } });
    return next(error);
  }
});

router.patch('/:id/status', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = statusSchema.parse(req.body);
    const existing = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!existing) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });
    if (!input.isActive) {
      const activeLocations = await pool.query('SELECT COUNT(*)::int AS count FROM warehouse_locations WHERE warehouse_id = $1 AND is_active = TRUE', [existing.id]);
      if (Number(activeLocations.rows[0].count) > 0) {
        return res.status(409).json({ error: { code: 'ACTIVE_LOCATIONS_EXIST', message: 'Deactivate all active warehouse locations before deactivating the warehouse.' } });
      }
    }
    const result = await pool.query(
      'UPDATE warehouses SET is_active = $1, updated_at = NOW() WHERE id = $2 AND company_id = $3 ' +
      'RETURNING id, company_id, code, name, address, is_active, created_at, updated_at',
      [input.isActive, existing.id, req.tenant.companyId],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'WAREHOUSE_STATUS_CHANGED', 'warehouse', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, existing.id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ isActive: input.isActive })],
    );
    return res.json({ warehouse: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid warehouse status.' } });
    return next(error);
  }
});

router.get('/:id/locations', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.read'), async (req, res, next) => {
  try {
    const warehouse = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!warehouse) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });
    const result = await pool.query(
      'SELECT id, warehouse_id, code, zone, bin, is_active, created_at, updated_at ' +
      'FROM warehouse_locations WHERE warehouse_id = $1 ORDER BY zone NULLS LAST, bin NULLS LAST, code ASC',
      [warehouse.id],
    );
    return res.json({ warehouse, locations: result.rows });
  } catch (error) { return next(error); }
});

router.post('/:id/locations', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = locationSchema.parse(req.body);
    const warehouse = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!warehouse) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });
    if (!warehouse.is_active) return res.status(409).json({ error: { code: 'WAREHOUSE_INACTIVE', message: 'Cannot add a location to an inactive warehouse.' } });

    const result = await pool.query(
      'INSERT INTO warehouse_locations (warehouse_id, code, zone, bin) VALUES ($1, $2, $3, $4) ' +
      'RETURNING id, warehouse_id, code, zone, bin, is_active, created_at, updated_at',
      [warehouse.id, input.code, input.zone || null, input.bin || null],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'LOCATION_CREATED', 'warehouse_location', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ warehouseId: warehouse.id, code: input.code })],
    );
    return res.status(201).json({ location: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid location request.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'LOCATION_CODE_EXISTS', message: 'Location code already exists in this warehouse.' } });
    return next(error);
  }
});

router.patch('/:id/locations/:locationId', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = locationUpdateSchema.parse(req.body);
    if (Object.keys(input).length === 0) return res.status(400).json({ error: { code: 'NO_FIELDS', message: 'At least one field is required.' } });
    const warehouse = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!warehouse) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });

    const current = await pool.query(
      'SELECT id FROM warehouse_locations WHERE id = $1 AND warehouse_id = $2 LIMIT 1',
      [req.params.locationId, warehouse.id],
    );
    if (current.rowCount === 0) return res.status(404).json({ error: { code: 'LOCATION_NOT_FOUND', message: 'Location not found.' } });

    const result = await pool.query(
      'UPDATE warehouse_locations SET code = COALESCE($1, code), zone = CASE WHEN $2::boolean THEN $3 ELSE zone END, ' +
      'bin = CASE WHEN $4::boolean THEN $5 ELSE bin END, updated_at = NOW() ' +
      'WHERE id = $6 AND warehouse_id = $7 ' +
      'RETURNING id, warehouse_id, code, zone, bin, is_active, created_at, updated_at',
      [input.code ?? null, input.zone !== undefined, input.zone ?? null, input.bin !== undefined, input.bin ?? null, current.rows[0].id, warehouse.id],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'LOCATION_UPDATED', 'warehouse_location', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, current.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ warehouseId: warehouse.id, changedFields: Object.keys(input) })],
    );
    return res.json({ location: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid location update.' } });
    if (error.code === '23505') return res.status(409).json({ error: { code: 'LOCATION_CODE_EXISTS', message: 'Location code already exists in this warehouse.' } });
    return next(error);
  }
});

router.patch('/:id/locations/:locationId/status', requireAuth, requireApprovedDevice, requireRole('admin'), requireTenantContext, requirePermission('warehouse.manage'), async (req, res, next) => {
  try {
    const input = statusSchema.parse(req.body);
    const warehouse = await getWarehouse(req.params.id, req.tenant.companyId);
    if (!warehouse) return res.status(404).json({ error: { code: 'WAREHOUSE_NOT_FOUND', message: 'Warehouse not found.' } });
    const current = await pool.query('SELECT id FROM warehouse_locations WHERE id = $1 AND warehouse_id = $2 LIMIT 1', [req.params.locationId, warehouse.id]);
    if (current.rowCount === 0) return res.status(404).json({ error: { code: 'LOCATION_NOT_FOUND', message: 'Location not found.' } });

    const result = await pool.query(
      'UPDATE warehouse_locations SET is_active = $1, updated_at = NOW() WHERE id = $2 AND warehouse_id = $3 ' +
      'RETURNING id, warehouse_id, code, zone, bin, is_active, created_at, updated_at',
      [input.isActive, current.rows[0].id, warehouse.id],
    );
    await pool.query(
      'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
      "VALUES ($1, $2, 'LOCATION_STATUS_CHANGED', 'warehouse_location', $3, $4, $5, $6)",
      [req.tenant.companyId, req.user.sub, current.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ warehouseId: warehouse.id, isActive: input.isActive })],
    );
    return res.json({ location: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid location status.' } });
    return next(error);
  }
});

module.exports = router;
