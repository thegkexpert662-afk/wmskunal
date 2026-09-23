const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');

router.get(
  '/me',
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requirePermission('company.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT id, company_code, name, logo_url, address, gstin, email, mobile,
                invoice_locked, created_at, updated_at
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

const updateSchema = z.object({
  name: z.string().trim().min(1).max(200).optional(),
  logoUrl: z.string().trim().url().max(2000).optional(),
  address: z.string().trim().max(2000).optional(),
  gstin: z.string().trim().max(20).optional(),
  email: z.string().trim().email().max(200).optional(),
  mobile: z.string().trim().max(30).optional(),
});

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
         RETURNING id, company_code, name, logo_url, address, gstin, email, mobile,
                   invoice_locked, created_at, updated_at`,
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
