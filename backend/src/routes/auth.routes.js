const router = require('express').Router();
const argon2 = require('argon2');
const { z } = require('zod');

const pool = require('../config/db');
const { signAccessToken } = require('../utils/jwt');

const loginSchema = z.object({
  username: z.string().trim().min(1).max(100),
  password: z.string().min(1).max(200),
  deviceCredentialId: z.string().trim().min(16).max(500).optional(),
});

router.post('/login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);

    const result = await pool.query(
      'SELECT id, company_id, client_id, username, full_name, password_hash, role, is_active FROM users WHERE username = $1 LIMIT 1',
      [input.username],
    );

    const user = result.rows[0];
    if (!user || !user.is_active) {
      return res.status(401).json({ error: { code: 'INVALID_CREDENTIALS', message: 'Invalid username or password.' } });
    }

    const valid = await argon2.verify(user.password_hash, input.password);
    if (!valid) {
      return res.status(401).json({ error: { code: 'INVALID_CREDENTIALS', message: 'Invalid username or password.' } });
    }

    const devices = await pool.query(
      'SELECT id, status FROM devices WHERE user_id = $1 ORDER BY first_registered_at DESC',
      [user.id],
    );

    let device = null;
    if (input.deviceCredentialId) {
      const deviceResult = await pool.query(
        'SELECT id, status FROM devices WHERE user_id = $1 AND credential_id = $2 LIMIT 1',
        [user.id, input.deviceCredentialId],
      );
      device = deviceResult.rows[0] || null;
      if (!device || device.status !== 'approved') {
        return res.status(403).json({
          error: { code: 'DEVICE_NOT_APPROVED', message: 'This device is not approved for WMS access.' },
        });
      }
    } else if (devices.rowCount > 0) {
      return res.status(403).json({
        error: { code: 'DEVICE_REQUIRED', message: 'An approved device is required for WMS access.' },
      });
    }

    if (device) {
      await pool.query(
        'UPDATE devices SET last_seen_at = NOW(), last_ip = $1, user_agent = $2 WHERE id = $3',
        [req.ip || null, req.get('user-agent') || null, device.id],
      );
    }

    const token = signAccessToken(user, device ? device.id : null);
    return res.json({
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
      deviceStatus: device ? 'approved' : 'not_registered',
      deviceEnrollmentRequired: !device,
      user: {
        id: user.id, username: user.username, fullName: user.full_name,
        role: user.role, companyId: user.company_id, clientId: user.client_id,
      },
    });
  } catch (error) {
    if (error.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid login request.' } });
    return next(error);
  }
});

module.exports = router;