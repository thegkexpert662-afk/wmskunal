const router = require('express').Router();
const { z } = require('zod');
const argon2 = require('argon2');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const userSelect = 'id, company_id, client_id, username, email, full_name, role, is_active, created_at, updated_at';

const createSchema = z.object({
  username: z.string().trim().min(3).max(100).regex(/^[A-Za-z0-9._-]+$/),
  email: z.string().trim().email().max(200).optional(),
  fullName: z.string().trim().min(1).max(150),
  password: z.string().min(12).max(200),
  role: z.enum(['admin', 'client']),
  companyId: z.string().uuid().optional(),
  clientId: z.string().uuid().optional(),
});

const updateSchema = z.object({
  email: z.string().trim().email().max(200).optional(),
  fullName: z.string().trim().min(1).max(150).optional(),
  role: z.enum(['admin', 'client']).optional(),
  clientId: z.string().uuid().nullable().optional(),
  password: z.string().min(12).max(200).optional(),
});

const statusSchema = z.object({ isActive: z.boolean() });

async function validateClient(companyId, clientId) {
  if (!clientId) return true;
  const result = await pool.query(
    'SELECT 1 FROM clients WHERE id = $1 AND company_id = $2 AND is_active = TRUE LIMIT 1',
    [clientId, companyId],
  );
  return result.rowCount > 0;
}

router.get(
  '/',
  requireAuth,
  requireApprovedDevice,
  requireRole('master_admin'),
  requirePermission('user.read'),
  async (_req, res, next) => {
    try {
      const result = await pool.query(
        'SELECT u.id, u.company_id, c.company_code, c.name AS company_name, ' +
        'u.client_id, cl.client_code, cl.name AS client_name, u.username, u.email, ' +
        'u.full_name, u.role, u.is_active, u.created_at, u.updated_at ' +
        'FROM users u LEFT JOIN companies c ON c.id = u.company_id ' +
        'LEFT JOIN clients cl ON cl.id = u.client_id ORDER BY u.created_at DESC',
      );
      return res.json({ users: result.rows });
    } catch (error) {
      return next(error);
    }
  },
);

router.get(
  '/company',
  requireAuth,
  requireApprovedDevice,
  requireRole('admin'),
  requireTenantContext,
  requirePermission('user.read'),
  async (req, res, next) => {
    try {
      const result = await pool.query(
        'SELECT ' + userSelect + ' FROM users WHERE company_id = $1 ' +
        "AND role IN ('admin', 'client') ORDER BY full_name ASC",
        [req.tenant.companyId],
      );
      return res.json({ users: result.rows });
    } catch (error) {
      return next(error);
    }
  },
);

router.post(
  '/',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.manage'),
  async (req, res, next) => {
    try {
      const input = createSchema.parse(req.body);
      const isMaster = req.user.role === 'master_admin';
      if (!isMaster && req.user.role !== 'admin') {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to create users.' } });
      }

      if (!isMaster) {
        // Admin user creation is always tenant-scoped; never trust a companyId from the request body.
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
      }
      const companyId = isMaster ? input.companyId : req.tenant.companyId;
      if (!companyId) {
        return res.status(400).json({ error: { code: 'COMPANY_REQUIRED', message: 'Company is required.' } });
      }
      if (input.role === 'client' && !input.clientId) {
        return res.status(400).json({ error: { code: 'CLIENT_REQUIRED', message: 'Client is required for a client user.' } });
      }
      if (input.role === 'admin' && input.clientId) {
        return res.status(400).json({ error: { code: 'CLIENT_NOT_ALLOWED', message: 'Admin users cannot be linked to a client.' } });
      }

      const company = await pool.query('SELECT 1 FROM companies WHERE id = $1 LIMIT 1', [companyId]);
      if (company.rowCount === 0) {
        return res.status(404).json({ error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' } });
      }
      if (!(await validateClient(companyId, input.clientId))) {
        return res.status(400).json({ error: { code: 'CLIENT_COMPANY_MISMATCH', message: 'Client does not belong to the selected company or is inactive.' } });
      }

      const passwordHash = await argon2.hash(input.password);
      const result = await pool.query(
        'INSERT INTO users (company_id, client_id, username, email, password_hash, full_name, role) ' +
        'VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING ' + userSelect,
        [companyId, input.clientId || null, input.username, input.email || null, passwordHash, input.fullName, input.role],
      );

      await pool.query(
        'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
        "VALUES ($1, $2, 'USER_CREATED', 'user', $3, $4, $5, $6)",
        [companyId, req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null,
          JSON.stringify({ role: input.role, username: input.username })],
      );
      return res.status(201).json({ user: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid user request.' } });
      if (error.code === '23505') return res.status(409).json({ error: { code: 'USERNAME_OR_EMAIL_EXISTS', message: 'Username or email already exists.' } });
      return next(error);
    }
  },
);

router.patch(
  '/:id',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.manage'),
  async (req, res, next) => {
    try {
      const input = updateSchema.parse(req.body);
      if (!['master_admin', 'admin'].includes(req.user.role)) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to manage users.' } });
      }

      const params = [req.params.id];
      let scope = '';
      if (req.user.role === 'admin') {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
        scope = ' AND company_id = $2';
        params.push(req.tenant.companyId);
      }

      const current = await pool.query(
        'SELECT id, company_id, client_id, role FROM users WHERE id = $1' + scope + ' LIMIT 1',
        params,
      );
      if (current.rowCount === 0) return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found.' } });

      const existing = current.rows[0];
      if (existing.role === 'master_admin') {
        return res.status(403).json({ error: { code: 'MASTER_USER_PROTECTED', message: 'Master Admin users cannot be changed from this endpoint.' } });
      }

      const nextRole = input.role || existing.role;
      if (nextRole === 'admin' && input.clientId) {
        return res.status(400).json({ error: { code: 'CLIENT_NOT_ALLOWED', message: 'Admin users cannot be linked to a client.' } });
      }
      const nextClientId = nextRole === 'client'
        ? (input.clientId !== undefined ? input.clientId : existing.client_id)
        : null;

      if (nextRole === 'client' && !(await validateClient(existing.company_id, nextClientId))) {
        return res.status(400).json({ error: { code: 'CLIENT_COMPANY_MISMATCH', message: 'Client does not belong to the user company or is inactive.' } });
      }

      const passwordHash = input.password ? await argon2.hash(input.password) : null;
      const result = await pool.query(
        'UPDATE users SET email = COALESCE($1, email), full_name = COALESCE($2, full_name), ' +
        'role = $3, client_id = $4, password_hash = COALESCE($5, password_hash), updated_at = NOW() ' +
        'WHERE id = $6 RETURNING ' + userSelect,
        [input.email ?? null, input.fullName ?? null, nextRole, nextClientId, passwordHash, existing.id],
      );

      await pool.query(
        'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
        "VALUES ($1, $2, 'USER_UPDATED', 'user', $3, $4, $5, $6)",
        [existing.company_id, req.user.sub, existing.id, req.ip || null, req.get('user-agent') || null,
          JSON.stringify({ role: nextRole, passwordChanged: Boolean(input.password) })],
      );
      return res.json({ user: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid user update.' } });
      if (error.code === '23505') return res.status(409).json({ error: { code: 'EMAIL_EXISTS', message: 'Email already exists.' } });
      return next(error);
    }
  },
);

router.patch(
  '/:id/status',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.manage'),
  async (req, res, next) => {
    try {
      const input = statusSchema.parse(req.body);
      if (!['master_admin', 'admin'].includes(req.user.role)) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to manage users.' } });
      }

      const params = [req.params.id];
      let scope = '';
      if (req.user.role === 'admin') {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
        scope = ' AND company_id = $2';
        params.push(req.tenant.companyId);
      }

      const current = await pool.query(
        'SELECT id, company_id, role FROM users WHERE id = $1' + scope + ' LIMIT 1',
        params,
      );
      if (current.rowCount === 0) return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found.' } });
      if (current.rows[0].role === 'master_admin') {
        return res.status(403).json({ error: { code: 'MASTER_USER_PROTECTED', message: 'Master Admin users cannot be changed from this endpoint.' } });
      }

      const result = await pool.query(
        'UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING ' + userSelect,
        [input.isActive, req.params.id],
      );

      await pool.query(
        'INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata) ' +
        "VALUES ($1, $2, 'USER_STATUS_CHANGED', 'user', $3, $4, $5, $6)",
        [current.rows[0].company_id, req.user.sub, result.rows[0].id, req.ip || null, req.get('user-agent') || null,
          JSON.stringify({ isActive: input.isActive })],
      );
      return res.json({ user: result.rows[0] });
    } catch (error) {
      if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid user status.' } });
      return next(error);
    }
  },
);

module.exports = router;
