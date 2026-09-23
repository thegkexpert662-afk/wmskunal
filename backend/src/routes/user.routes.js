const router = require('express').Router();
const { z } = require('zod');
const argon2 = require('argon2');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireRole } = require('../middleware/role');
const { requireTenantContext } = require('../middleware/tenant');

const STAFF_ROLES = [
  'warehouse_manager',
  'warehouse_supervisor',
  'warehouse_operator',
  'warehouse_qc',
  'gate_operator',
  'inventory_user',
  'dispatch_user',
];

const ALL_ROLES = ['admin', 'client', ...STAFF_ROLES];

const userColumns = ['id','user_code','employee_code','company_id','client_id','username','email','full_name','phone','department','designation','role','is_active','created_at','updated_at'];
const userSelect = userColumns.map((c) => 'u.' + c).join(', ');
const userReturning = userColumns.join(', ');

const createSchema = z.object({
  username: z.string().trim().min(3).max(100).regex(/^[A-Za-z0-9._-]+$/),
  email: z.string().trim().email().max(200).optional(),
  fullName: z.string().trim().min(1).max(150),
  phone: z.string().trim().max(30).optional(),
  employeeCode: z.string().trim().max(60).optional(),
  department: z.string().trim().max(100).optional(),
  designation: z.string().trim().max(120).optional(),
  password: z.string().min(12).max(200),
  role: z.enum(ALL_ROLES),
  companyId: z.string().uuid().optional(),
  clientId: z.string().uuid().optional(),
  warehouseIds: z.array(z.string().uuid()).max(50).optional().default([]),
  primaryWarehouseId: z.string().uuid().nullable().optional(),
});

const updateSchema = createSchema.partial().extend({
  password: z.string().min(12).max(200).optional(),
  clientId: z.string().uuid().nullable().optional(),
  warehouseIds: z.array(z.string().uuid()).max(50).optional(),
  primaryWarehouseId: z.string().uuid().nullable().optional(),
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

async function validateWarehouses(companyId, warehouseIds) {
  if (!warehouseIds.length) return true;
  const result = await pool.query(
    'SELECT id FROM warehouses WHERE company_id = $1 AND is_active = TRUE AND id = ANY($2::uuid[])',
    [companyId, warehouseIds],
  );
  return result.rowCount === new Set(warehouseIds).size;
}

async function getWarehouses(userId) {
  const result = await pool.query(
    `SELECT uw.warehouse_id, w.code, w.name, uw.is_primary
     FROM user_warehouses uw
     JOIN warehouses w ON w.id = uw.warehouse_id
     WHERE uw.user_id = $1
     ORDER BY uw.is_primary DESC, w.name ASC`,
    [userId],
  );
  return result.rows;
}

async function writeAssignments(client, userId, warehouseIds, primaryWarehouseId, assignedBy) {
  await client.query('DELETE FROM user_warehouses WHERE user_id = $1', [userId]);
  if (!warehouseIds.length) return;
  const primary = primaryWarehouseId && warehouseIds.includes(primaryWarehouseId)
    ? primaryWarehouseId
    : warehouseIds[0];

  for (const warehouseId of warehouseIds) {
    await client.query(
      'INSERT INTO user_warehouses (user_id, warehouse_id, is_primary, assigned_by) VALUES ($1, $2, $3, $4)',
      [userId, warehouseId, warehouseId === primary, assignedBy],
    );
  }
}

async function serializeUser(row) {
  return {
    ...row,
    warehouses: await getWarehouses(row.id),
  };
}

router.get(
  '/',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.read'),
  async (req, res, next) => {
    try {
      const isMaster = req.user.role === 'master_admin';
      if (!isMaster && req.user.role !== 'admin') {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to view users.' } });
      }

      let companyId = null;
      if (!isMaster) {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
        companyId = req.tenant.companyId;
      }

      const params = [];
      let where = '';
      if (companyId) {
        params.push(companyId);
        where = 'WHERE u.company_id = $1';
      }

      const result = await pool.query(
        `SELECT ${userSelect}, c.company_code, c.name AS company_name,
                cl.client_code, cl.name AS client_name,
                COALESCE(
                  json_agg(
                    json_build_object('warehouseId', w.id, 'code', w.code, 'name', w.name, 'isPrimary', uw.is_primary)
                    ORDER BY uw.is_primary DESC, w.name
                  ) FILTER (WHERE w.id IS NOT NULL), '[]'
                ) AS warehouses
           FROM users u
           LEFT JOIN companies c ON c.id = u.company_id
           LEFT JOIN clients cl ON cl.id = u.client_id
           LEFT JOIN user_warehouses uw ON uw.user_id = u.id
           LEFT JOIN warehouses w ON w.id = uw.warehouse_id
           ${where}
          GROUP BY u.id, c.company_code, c.name, cl.client_code, cl.name
          ORDER BY u.created_at DESC`,
        params,
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
        `SELECT ${userSelect}
         FROM users u
         WHERE u.company_id = $1
         ORDER BY u.full_name ASC`,
        [req.tenant.companyId],
      );
      return res.json({ users: result.rows });
    } catch (error) {
      return next(error);
    }
  },
);

router.get(
  '/roles',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.read'),
  async (_req, res) => {
    return res.json({
      roles: [
        { key: 'admin', label: 'Company Admin' },
        { key: 'client', label: 'Client User' },
        { key: 'warehouse_manager', label: 'Warehouse Manager' },
        { key: 'warehouse_supervisor', label: 'Warehouse Supervisor' },
        { key: 'warehouse_operator', label: 'Warehouse Operator' },
        { key: 'warehouse_qc', label: 'Warehouse QC User' },
        { key: 'gate_operator', label: 'Gate Operator' },
        { key: 'inventory_user', label: 'Inventory User' },
        { key: 'dispatch_user', label: 'Dispatch User' },
      ],
    });
  },
);

router.get(
  '/warehouses',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.read'),
  async (req, res, next) => {
    try {
      const isMaster = req.user.role === 'master_admin';
      if (!isMaster && req.user.role !== 'admin') {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to view warehouses.' } });
      }
      let companyId;
      if (isMaster) {
        companyId = req.query.companyId?.toString();
        if (!companyId) return res.status(400).json({ error: { code: 'COMPANY_REQUIRED', message: 'Company is required.' } });
      } else {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
        companyId = req.tenant.companyId;
      }
      const result = await pool.query(
        'SELECT id, code, name FROM warehouses WHERE company_id = $1 AND is_active = TRUE ORDER BY name ASC',
        [companyId],
      );
      return res.json({ warehouses: result.rows });
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
    const db = await pool.connect();
    try {
      const input = createSchema.parse(req.body);
      const isMaster = req.user.role === 'master_admin';
      if (!isMaster && req.user.role !== 'admin') {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Only Admin can create users.' } });
      }
      if (!isMaster) {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
      }

      const companyId = isMaster ? input.companyId : req.tenant.companyId;
      if (!companyId) return res.status(400).json({ error: { code: 'COMPANY_REQUIRED', message: 'Company is required.' } });
      if (input.role === 'client' && !input.clientId) {
        return res.status(400).json({ error: { code: 'CLIENT_REQUIRED', message: 'Client is required for a client user.' } });
      }
      if (input.role !== 'client' && input.clientId) {
        return res.status(400).json({ error: { code: 'CLIENT_NOT_ALLOWED', message: 'Only Client User can be linked to a client.' } });
      }
      if (!STAFF_ROLES.includes(input.role) && input.warehouseIds.length) {
        return res.status(400).json({ error: { code: 'WAREHOUSE_NOT_ALLOWED', message: 'Warehouse assignment is only for warehouse and operational users.' } });
      }
      if (!await validateClient(companyId, input.clientId)) {
        return res.status(400).json({ error: { code: 'CLIENT_COMPANY_MISMATCH', message: 'Client does not belong to the selected company or is inactive.' } });
      }
      if (!await validateWarehouses(companyId, input.warehouseIds)) {
        return res.status(400).json({ error: { code: 'WAREHOUSE_COMPANY_MISMATCH', message: 'One or more warehouses are invalid or inactive.' } });
      }

      const company = await pool.query('SELECT id, is_active FROM companies WHERE id = $1 LIMIT 1', [companyId]);
      if (!company.rowCount) return res.status(404).json({ error: { code: 'COMPANY_NOT_FOUND', message: 'Company not found.' } });
      if (!company.rows[0].is_active) return res.status(403).json({ error: { code: 'COMPANY_INACTIVE', message: 'Cannot create a user for an inactive company.' } });

      const normalizedUsername = input.username.trim().toLowerCase();
      const existingUsername = await pool.query(
        'SELECT id FROM users WHERE LOWER(TRIM(username)) = $1 LIMIT 1',
        [normalizedUsername],
      );
      if (existingUsername.rowCount) {
        return res.status(409).json({
          error: {
            code: 'USERNAME_EXISTS',
            message: 'Username already exists. Please choose a different username.',
          },
        });
      }

      await db.query('BEGIN');
      const passwordHash = await argon2.hash(input.password);
      const inserted = await db.query(
        `INSERT INTO users
          (company_id, employee_code, username, email, password_hash, full_name, phone, department, designation, role, client_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
         RETURNING ${userReturning}`,
        [companyId, input.employeeCode || null, normalizedUsername, input.email || null, passwordHash, input.fullName,
          input.phone || null, input.department || null, input.designation || null, input.role, input.clientId || null],
      );
      const user = await serializeUser(inserted.rows[0]);
      await writeAssignments(db, user.id, input.warehouseIds, input.primaryWarehouseId, req.user.sub);

      await db.query(
        `INSERT INTO audit_logs (company_id, user_id, action, entity_type, entity_id, ip_address, user_agent, metadata)
         VALUES ($1,$2,'USER_CREATED','user',$3,$4,$5,$6)`,
        [companyId, req.user.sub, user.id, req.ip || null, req.get('user-agent') || null,
          JSON.stringify({ role: input.role, username: input.username, warehouseIds: input.warehouseIds })],
      );
      await db.query('COMMIT');
      return res.status(201).json({ user: await serializeUser(user) });
    } catch (error) {
      await db.query('ROLLBACK').catch(() => {});
      if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid user request.' } });
      if (error.code === '23505') return res.status(409).json({ error: { code: 'USERNAME_EMAIL_OR_CODE_EXISTS', message: 'Username, email or employee code already exists.' } });
      return next(error);
    } finally {
      db.release();
    }
  },
);

router.get(
  '/:id',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.read'),
  async (req, res, next) => {
    try {
      const params = [req.params.id];
      let scope = '';
      if (req.user.role === 'admin') {
        await requireTenantContext(req, res, () => {});
        if (res.headersSent) return;
        scope = ' AND u.company_id = $2';
        params.push(req.tenant.companyId);
      } else if (req.user.role !== 'master_admin') {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not have permission to view users.' } });
      }
      const result = await pool.query(
        `SELECT ${userSelect}, c.company_code, c.name AS company_name, cl.client_code, cl.name AS client_name
         FROM users u
         LEFT JOIN companies c ON c.id = u.company_id
         LEFT JOIN clients cl ON cl.id = u.client_id
         WHERE u.id = $1${scope} LIMIT 1`,
        params,
      );
      if (!result.rowCount) return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found.' } });
      return res.json({ user: await serializeUser(result.rows[0]) });
    } catch (error) { return next(error); }
  },
);

router.patch(
  '/:id',
  requireAuth,
  requireApprovedDevice,
  requirePermission('user.manage'),
  async (req, res, next) => {
    const db = await pool.connect();
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
      if (!current.rowCount) return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found.' } });
      const existing = current.rows[0];
      if (existing.id === req.user.sub) return res.status(400).json({ error: { code: 'SELF_MANAGEMENT_BLOCKED', message: 'Use the account/profile flow to manage your own profile.' } });
      if (existing.role === 'master_admin') return res.status(403).json({ error: { code: 'MASTER_USER_PROTECTED', message: 'Master Admin users cannot be changed from this endpoint.' } });

      const nextRole = input.role || existing.role;
      const nextClientId = nextRole === 'client' ? (input.clientId !== undefined ? input.clientId : existing.client_id) : null;
      const warehouseIds = input.warehouseIds !== undefined ? input.warehouseIds : (await getWarehouses(existing.id)).map(w => w.warehouse_id);
      if (nextRole === 'client' && !nextClientId) return res.status(400).json({ error: { code: 'CLIENT_REQUIRED', message: 'Client is required for a client user.' } });
      if (nextRole !== 'client' && input.clientId) return res.status(400).json({ error: { code: 'CLIENT_NOT_ALLOWED', message: 'Only Client User can be linked to a client.' } });
      if (!STAFF_ROLES.includes(nextRole) && warehouseIds.length) return res.status(400).json({ error: { code: 'WAREHOUSE_NOT_ALLOWED', message: 'Warehouse assignment is only for warehouse and operational users.' } });
      if (nextRole === 'client' && !(await validateClient(existing.company_id, nextClientId))) return res.status(400).json({ error: { code: 'CLIENT_COMPANY_MISMATCH', message: 'Client does not belong to the user company or is inactive.' } });
      if (!(await validateWarehouses(existing.company_id, warehouseIds))) return res.status(400).json({ error: { code: 'WAREHOUSE_COMPANY_MISMATCH', message: 'One or more warehouses are invalid or inactive.' } });

      await db.query('BEGIN');
      const passwordHash = input.password ? await argon2.hash(input.password) : null;
      const updated = await db.query(
        `UPDATE users SET
          email = COALESCE($1,email), full_name = COALESCE($2,full_name),
          phone = COALESCE($3,phone), employee_code = COALESCE($4,employee_code),
          department = COALESCE($5,department), designation = COALESCE($6,designation),
          role = $7, client_id = $8, password_hash = COALESCE($9,password_hash), updated_at = NOW()
         WHERE id = $10 RETURNING ${userSelect}`,
        [input.email ?? null, input.fullName ?? null, input.phone ?? null, input.employeeCode ?? null,
          input.department ?? null, input.designation ?? null, nextRole, nextClientId, passwordHash, existing.id],
      );
      await writeAssignments(db, existing.id, warehouseIds, input.primaryWarehouseId, req.user.sub);
      const updatedUser = updated.rows[0];
      await db.query(
        `INSERT INTO audit_logs (company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
         VALUES ($1,$2,'USER_UPDATED','user',$3,$4,$5,$6)`,
        [existing.company_id, req.user.sub, existing.id, req.ip || null, req.get('user-agent') || null,
          JSON.stringify({ role: nextRole, warehouseIds, passwordChanged: Boolean(input.password) })],
      );
      await db.query('COMMIT');
      return res.json({ user: await serializeUser(updatedUser) });
    } catch (error) {
      await db.query('ROLLBACK').catch(() => {});
      if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid user update.' } });
      if (error.code === '23505') return res.status(409).json({ error: { code: 'EMAIL_OR_EMPLOYEE_CODE_EXISTS', message: 'Email or employee code already exists.' } });
      return next(error);
    } finally { db.release(); }
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
      const current = await pool.query('SELECT id, company_id, role FROM users WHERE id = $1' + scope + ' LIMIT 1', params);
      if (!current.rowCount) return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found.' } });
      if (current.rows[0].id === req.user.sub) return res.status(400).json({ error: { code: 'SELF_STATUS_CHANGE_BLOCKED', message: 'You cannot change your own status here.' } });
      if (current.rows[0].role === 'master_admin') return res.status(403).json({ error: { code: 'MASTER_USER_PROTECTED', message: 'Master Admin users cannot be changed from this endpoint.' } });

      const result = await pool.query(
        'UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING ' + userSelect,
        [input.isActive, req.params.id],
      );
      await pool.query(
        `INSERT INTO audit_logs (company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
         VALUES ($1,$2,'USER_STATUS_CHANGED','user',$3,$4,$5,$6)`,
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
