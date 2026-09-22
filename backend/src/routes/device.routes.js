const router = require('express').Router();
const { z } = require('zod');

const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');

const registerSchema = z.object({
  deviceName: z.string().trim().min(1).max(150),
  deviceType: z.string().trim().min(1).max(50),
  credentialId: z.string().trim().min(16).max(500),
});

const statusSchema = z.object({
  status: z.enum(['approved', 'rejected', 'revoked']),
});

router.post('/register', requireAuth, async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const existing = await pool.query(
      'SELECT id FROM devices WHERE credential_id = $1 LIMIT 1',
      [input.credentialId],
    );
    if (existing.rowCount > 0) {
      return res.status(409).json({
        error: { code: 'DEVICE_ALREADY_REGISTERED', message: 'This device credential is already registered.' },
      });
    }
    const result = await pool.query(
      `INSERT INTO devices
        (company_id, user_id, device_name, device_type, credential_id, status, user_agent)
       VALUES ($1, $2, $3, $4, $5, 'pending', $6)
       RETURNING id, company_id, user_id, device_name, device_type, status, first_registered_at`,
      [req.user.companyId || null, req.user.sub, input.deviceName, input.deviceType, input.credentialId, req.get('user-agent') || null],
    );
    return res.status(201).json({ device: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid device registration request.' } });
    return next(error);
  }
});

router.get('/pending', requireAuth, requireRole('master_admin'), async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT d.id, d.company_id, d.user_id, d.device_name, d.device_type,
              d.status, d.first_registered_at, d.last_seen_at, d.last_ip,
              u.username, u.full_name
       FROM devices d
       LEFT JOIN users u ON u.id = d.user_id
       WHERE d.status = 'pending'
       ORDER BY d.first_registered_at ASC`,
    );
    return res.json({ devices: result.rows });
  } catch (error) { return next(error); }
});

router.get('/', requireAuth, requireRole('master_admin'), async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT d.id, d.company_id, d.user_id, d.device_name, d.device_type,
              d.status, d.first_registered_at, d.last_seen_at, d.last_ip,
              d.approved_by, d.approved_at, u.username, u.full_name
       FROM devices d
       LEFT JOIN users u ON u.id = d.user_id
       ORDER BY d.first_registered_at DESC`,
    );
    return res.json({ devices: result.rows });
  } catch (error) { return next(error); }
});

router.patch('/:id/status', requireAuth, requireRole('master_admin'), async (req, res, next) => {
  try {
    const input = statusSchema.parse(req.body);

    let result;
    if (input.status === 'approved') {
      result = await pool.query(
        `UPDATE devices
         SET status = 'approved',
             approved_by = $1,
             approved_at = NOW()
         WHERE id = $2
         RETURNING id, company_id, user_id, device_name, device_type, status,
                   first_registered_at, last_seen_at, approved_by, approved_at`,
        [req.user.sub, req.params.id],
      );
    } else if (input.status === 'rejected') {
      result = await pool.query(
        `UPDATE devices
         SET status = 'rejected'
         WHERE id = $1
         RETURNING id, company_id, user_id, device_name, device_type, status,
                   first_registered_at, last_seen_at, approved_by, approved_at`,
        [req.params.id],
      );
    } else {
      result = await pool.query(
        `UPDATE devices
         SET status = 'revoked'
         WHERE id = $1
         RETURNING id, company_id, user_id, device_name, device_type, status,
                   first_registered_at, last_seen_at, approved_by, approved_at`,
        [req.params.id],
      );
    }

    if (result.rowCount === 0) {
      return res.status(404).json({
        error: { code: 'DEVICE_NOT_FOUND', message: 'Device not found.' },
      });
    }

    await pool.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, $2, 'device', $3, $4::jsonb)`,
      [
        req.user.sub,
        'DEVICE_' + input.status.toUpperCase(),
        req.params.id,
        JSON.stringify({ status: input.status }),
      ],
    );

    return res.json({ device: result.rows[0] });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid device status.' } });
    return next(error);
  }
});

module.exports = router;
