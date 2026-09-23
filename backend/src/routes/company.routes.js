const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const updateSchema = z.object({
  name: z.string().trim().min(1).max(200).optional(),
  logoUrl: z.string().trim().url().max(2000).optional(),
  address: z.string().trim().max(2000).optional(),
  gstin: z.string().trim().max(20).optional(),
  email: z.string().trim().email().max(200).optional(),
  mobile: z.string().trim().max(30).optional(),
});

const createSchema = z.object({
  companyCode: z.string().trim().min(1).max(40).regex(/^[A-Za-z0-9_-]+$/),
  name: z.string().trim().min(1).max(200),
  logoUrl: z.string().trim().url().max(2000).optional(),
  address: z.string().trim().max(2000).optional(),
  gstin: z.string().trim().max(20).optional(),
  email: z.string().trim().email().max(200).optional(),
  mobile: z.string().trim().max(30).optional(),
});

const companySelect = `id, company_code, name, logo_url, address, gstin, email, mobile,
                         invoice_locked, is_active, created_at, updated_at`;

const moduleKeys = ['gate','inbound','grn','qc','putaway','warehouse','product','inventory','order','picking','packing','dispatch','return','invoice','report','client','stock_transfer'];

// Master Admin: technical/company administration only.
// No operational business data is exposed by these endpoints.
router.get(
  '/',
  requireAuth,
  requireApprovedDevice,
  requireRole('master_admin'),
  requirePermission('company.read'),
  async (_req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT ${companySelect}
         FROM companies
         ORDER BY name ASC`,
      );
      return res.json({ companies: result.rows });
    } catch (error) {
      return next(error);
    }
  },
);

router.post(
  '/',
  requireAuth,
  requireApprovedDevice,
  requireRole('master_admin'),
  requirePermission('company.manage'),
  async (req, res, next) => {
    try {
      const input = createSchema.parse(req.body);
      const result = await pool.query(
        `INSERT INTO companies
          (company_code, name, logo_url, address, gstin, email, mobile)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING ${companySelect}`,
        [
          input.companyCode,
          input.name,
          input.logoUrl || null,
          input.address || null,
          input.gstin || null,
          input.email || null,
          input.mobile || null,
        ],
      );

      await pool.query(
        `INSERT INTO audit_logs
          (user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
         VALUES ($1, 'COMPANY_CREATED', 'company', $2, $3, $4, $5)`,
        [
          req.user.sub,
          result.rows[0].id,
          req.ip || null,
          req.get('user-agent') || null,
          JSON.stringify({ companyCode: result.rows[0].company_code }),
        ],
      );

      return res.status(201).json({ company: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid company request.' },
        });
      }
      if (error.code === '23505') {
        return res.status(409).json({
          error: { code: 'COMPANY_CODE_EXISTS', message: 'Company code already exists.' },
        });
      }
      return next(error);
    }
  },
);

router.patch(
  '/:id',
  requireAuth,
  requireApprovedDevice,
  requireRole('master_admin'),
  requirePermission('company.manage'),
  async (req, res, next) => {
    try {
      const input = updateSchema.parse(req.body);
      const result = await pool.query(
        `UPDATE companies
         SET name = COALESCE($1, name),
             logo_url = COALESCE($2, logo_url),
             address = COALESCE($3, address),
             gstin = COALESCE($4, gstin),
             email = COALESCE($5, email),
             mobile = COALESCE($6, mobile),
             updated_at = NOW()
         WHERE id = $7
         RETURNING ${companySelect}`,
        [
          input.name ?? null,
          input.logoUrl ?? null,
          input.address ?? null,
          input.gstin ?? null,
          input.email ?? null,
          input.mobile ?? null,
          req.params.id,
        ],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' },
        });
      }

      await pool.query(
        `INSERT INTO audit_logs
          (user_id, action, entity_type, entity_id, ip_address, user_agent)
         VALUES ($1, 'COMPANY_UPDATED', 'company', $2, $3, $4)`,
        [
          req.user.sub,
          result.rows[0].id,
          req.ip || null,
          req.get('user-agent') || null,
        ],
      );

      return res.json({ company: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid company update.' },
        });
      }
      return next(error);
    }
  },
);


// Admin: own company profile only.
router.get(
  '/me',
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requirePermission('company.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT ${companySelect}
         FROM companies
         WHERE id = $1
         LIMIT 1`,
        [req.tenant.companyId],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' },
        });
      }

      return res.json({ company: result.rows[0] });
    } catch (error) {
      return next(error);
    }
  },
);

router.patch(
  '/me',
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requirePermission('company.manage'),
  async (req, res, next) => {
    try {
      const input = updateSchema.parse(req.body);
      const result = await pool.query(
        `UPDATE companies
         SET name = COALESCE($1, name),
             logo_url = COALESCE($2, logo_url),
             address = COALESCE($3, address),
             gstin = COALESCE($4, gstin),
             email = COALESCE($5, email),
             mobile = COALESCE($6, mobile),
             updated_at = NOW()
         WHERE id = $7
         RETURNING ${companySelect}`,
        [
          input.name ?? null,
          input.logoUrl ?? null,
          input.address ?? null,
          input.gstin ?? null,
          input.email ?? null,
          input.mobile ?? null,
          req.tenant.companyId,
        ],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' },
        });
      }

      return res.json({ company: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid company update.' },
        });
      }
      return next(error);
    }
  },
);


router.get('/:id', requireAuth, requireApprovedDevice, requireRole('master_admin'), requirePermission('company.read'), async (req, res, next) => {
  try {
    const result = await pool.query(`SELECT ${companySelect} FROM companies WHERE id = $1 LIMIT 1`, [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' } });
    return res.json({ company: result.rows[0] });
  } catch (error) { return next(error); }
});

router.patch('/:id/status', requireAuth, requireApprovedDevice, requireRole('master_admin'), requirePermission('company.manage'), async (req, res, next) => {
  try {
    const input = z.object({ isActive: z.boolean() }).parse(req.body);
    const result = await pool.query(`UPDATE companies SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING ${companySelect}`, [input.isActive, req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' } });
    await pool.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
       VALUES ($1, 'COMPANY_STATUS_CHANGED', 'company', $2, $3, $4, $5)`,
      [req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ isActive: input.isActive })],
    );
    return res.json({ company: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid company status.' } });
    return next(error);
  }
});

router.get('/:id/modules', requireAuth, requireApprovedDevice, requireRole('master_admin'), requirePermission('company.read'), async (req, res, next) => {
  try {
    const result = await pool.query('SELECT module_key, is_enabled FROM company_modules WHERE company_id = $1 ORDER BY module_key ASC', [req.params.id]);
    return res.json({ modules: moduleKeys.map(moduleKey => ({ moduleKey, isEnabled: result.rows.find(row => row.module_key === moduleKey)?.is_enabled ?? false })) });
  } catch (error) { return next(error); }
});

router.put('/:id/modules', requireAuth, requireApprovedDevice, requireRole('master_admin'), requirePermission('company.manage'), async (req, res, next) => {
  const schema = z.object({ modules: z.array(z.object({ moduleKey: z.string().trim(), isEnabled: z.boolean() })).min(1).max(moduleKeys.length) });
  try {
    const input = schema.parse(req.body);
    const unknown = input.modules.find(item => !moduleKeys.includes(item.moduleKey));
    if (unknown) return res.status(400).json({ error: { code: 'INVALID_MODULE', message: `Unsupported module: ${unknown.moduleKey}` } });

    const company = await pool.query('SELECT id FROM companies WHERE id = $1 LIMIT 1', [req.params.id]);
    if (company.rowCount === 0) return res.status(404).json({ error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' } });

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (const item of input.modules) {
        await client.query(
          `INSERT INTO company_modules (company_id, module_key, is_enabled)
           VALUES ($1, $2, $3)
           ON CONFLICT (company_id, module_key) DO UPDATE SET is_enabled = EXCLUDED.is_enabled`,
          [req.params.id, item.moduleKey, item.isEnabled],
        );
      }
      await client.query(
        `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
         VALUES ($1, 'COMPANY_MODULES_UPDATED', 'company', $2, $3, $4, $5)`,
        [req.user.sub, req.params.id, req.ip || null, req.get('user-agent') || null, JSON.stringify({ modules: input.modules })],
      );
      await client.query('COMMIT');
    } catch (error) { await client.query('ROLLBACK'); throw error; } finally { client.release(); }

    const result = await pool.query('SELECT module_key, is_enabled FROM company_modules WHERE company_id = $1 ORDER BY module_key ASC', [req.params.id]);
    return res.json({ modules: moduleKeys.map(moduleKey => ({ moduleKey, isEnabled: result.rows.find(row => row.module_key === moduleKey)?.is_enabled ?? false })) });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid company modules request.' } });
    return next(error);
  }
});

module.exports = router;
