const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const clientSchema = z.object({
  clientCode: z.string().trim().min(1).max(50),
  name: z.string().trim().min(1).max(200),
  email: z.string().trim().email().max(200).optional(),
  mobile: z.string().trim().max(30).optional(),
  gstin: z.string().trim().max(20).optional(),
  address: z.string().trim().max(2000).optional(),
});

const updateSchema = clientSchema.partial();

const adminRouter = router;
adminRouter.use(
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requireRole('admin'),
);

adminRouter.get(
  '/',
  requirePermission('client.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT id, client_code, name, email, mobile, gstin, address,
                is_active, created_at, updated_at
         FROM clients
         WHERE company_id = $1
         ORDER BY name ASC`,
        [req.tenant.companyId],
      );

      return res.json({ clients: result.rows });
    } catch (error) {
      return next(error);
    }
  },
);

adminRouter.post(
  '/',
  requirePermission('client.manage'),
  async (req, res, next) => {
    try {
      const input = clientSchema.parse(req.body);

      const result = await pool.query(
        `INSERT INTO clients
          (company_id, client_code, name, email, mobile, gstin, address)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, company_id, client_code, name, email, mobile, gstin,
                   address, is_active, created_at, updated_at`,
        [
          req.tenant.companyId,
          input.clientCode,
          input.name,
          input.email || null,
          input.mobile || null,
          input.gstin || null,
          input.address || null,
        ],
      );

      return res.status(201).json({ client: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid client request.' },
        });
      }
      if (error.code === '23505') {
        return res.status(409).json({
          error: {
            code: 'CLIENT_CODE_EXISTS',
            message: 'Client code already exists for this company.',
          },
        });
      }
      return next(error);
    }
  },
);

adminRouter.patch(
  '/:id',
  requirePermission('client.manage'),
  async (req, res, next) => {
    try {
      const input = updateSchema.parse(req.body);

      const result = await pool.query(
        `UPDATE clients
         SET client_code = COALESCE($1, client_code),
             name = COALESCE($2, name),
             email = COALESCE($3, email),
             mobile = COALESCE($4, mobile),
             gstin = COALESCE($5, gstin),
             address = COALESCE($6, address),
             updated_at = NOW()
         WHERE id = $7
           AND company_id = $8
         RETURNING id, company_id, client_code, name, email, mobile, gstin,
                   address, is_active, created_at, updated_at`,
        [
          input.clientCode ?? null,
          input.name ?? null,
          input.email ?? null,
          input.mobile ?? null,
          input.gstin ?? null,
          input.address ?? null,
          req.params.id,
          req.tenant.companyId,
        ],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'CLIENT_NOT_FOUND', message: 'Client not found.' },
        });
      }

      return res.json({ client: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid client update.' },
        });
      }
      if (error.code === '23505') {
        return res.status(409).json({
          error: {
            code: 'CLIENT_CODE_EXISTS',
            message: 'Client code already exists for this company.',
          },
        });
      }
      return next(error);
    }
  },
);

adminRouter.patch(
  '/:id/status',
  requirePermission('client.manage'),
  async (req, res, next) => {
    const schema = z.object({ isActive: z.boolean() });

    try {
      const input = schema.parse(req.body);

      const result = await pool.query(
        `UPDATE clients
         SET is_active = $1, updated_at = NOW()
         WHERE id = $2 AND company_id = $3
         RETURNING id, company_id, client_code, name, is_active, updated_at`,
        [input.isActive, req.params.id, req.tenant.companyId],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'CLIENT_NOT_FOUND', message: 'Client not found.' },
        });
      }

      return res.json({ client: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: 'Invalid client status.' },
        });
      }
      return next(error);
    }
  },
);

module.exports = router;
