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

const clientFields = `id, company_id, client_code, name, email, mobile, gstin, address,
                        is_active, created_at, updated_at`;

// Client portal: a client can only read its own client record.
router.get(
  '/me',
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requireRole('client'),
  requirePermission('profile.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT ${clientFields}
         FROM clients
         WHERE id = $1
           AND company_id = $2
           AND is_active = TRUE
         LIMIT 1`,
        [req.tenant.clientId, req.tenant.companyId],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'CLIENT_NOT_FOUND', message: 'Client profile not found.' },
        });
      }

      return res.json({ client: result.rows[0] });
    } catch (error) {
      return next(error);
    }
  },
);

// Admin client management: strictly limited to the current tenant company.
router.use(
  requireAuth,
  requireApprovedDevice,
  requireTenantContext,
  requireRole('admin'),
);

router.get(
  '/',
  requirePermission('client.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        `SELECT ${clientFields}
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

router.post(
  '/',
  requirePermission('client.manage'),
  async (req, res, next) => {
    try {
      const input = clientSchema.parse(req.body);

      const result = await pool.query(
        `INSERT INTO clients
          (company_id, client_code, name, email, mobile, gstin, address)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING ${clientFields}`,
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

      await pool.query(
        `INSERT INTO audit_logs
          (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
         VALUES ($1, $2, 'CLIENT_CREATED', 'client', $3, $4, $5, $6)`,
        [
          req.tenant.companyId,
          req.user.sub,
          result.rows[0].id,
          req.ip || null,
          req.get('user-agent') || null,
          JSON.stringify({ clientCode: result.rows[0].client_code }),
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

router.patch(
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
         RETURNING ${clientFields}`,
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

      await pool.query(
        `INSERT INTO audit_logs
          (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent)
         VALUES ($1, $2, 'CLIENT_UPDATED', 'client', $3, $4, $5)`,
        [
          req.tenant.companyId,
          req.user.sub,
          result.rows[0].id,
          req.ip || null,
          req.get('user-agent') || null,
        ],
      );

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

router.patch(
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
         RETURNING ${clientFields}`,
        [input.isActive, req.params.id, req.tenant.companyId],
      );

      if (result.rowCount === 0) {
        return res.status(404).json({
          error: { code: 'CLIENT_NOT_FOUND', message: 'Client not found.' },
        });
      }

      await pool.query(
        `INSERT INTO audit_logs
          (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
         VALUES ($1, $2, 'CLIENT_STATUS_CHANGED', 'client', $3, $4, $5, $6)`,
        [
          req.tenant.companyId,
          req.user.sub,
          result.rows[0].id,
          req.ip || null,
          req.get('user-agent') || null,
          JSON.stringify({ isActive: input.isActive }),
        ],
      );

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
