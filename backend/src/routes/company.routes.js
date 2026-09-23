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
                         invoice_locked, created_at, updated_at`;

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

module.exports = router;
