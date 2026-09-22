const pool = require('../config/db');

async function requireDeviceEnrollmentToken(req, res, next) {
  if (req.user?.purpose !== 'device_enrollment') return res.status(403).json({ error: { code: 'DEVICE_ENROLLMENT_TOKEN_REQUIRED', message: 'A device enrollment token is required for this operation.' } });
  return next();
}

async function requireApprovedDevice(req, res, next) {
  try {
    const deviceId = req.user?.deviceId;
    if (!deviceId) return res.status(403).json({ error: { code: 'DEVICE_REQUIRED', message: 'An approved device is required for this operation.' } });
    const result = await pool.query("SELECT id FROM devices WHERE id = $1 AND user_id = $2 AND status = 'approved' LIMIT 1", [deviceId, req.user.sub]);
    if (result.rowCount === 0) return res.status(403).json({ error: { code: 'DEVICE_NOT_APPROVED', message: 'This device is not approved for WMS access.' } });
    await pool.query('UPDATE devices SET last_seen_at = NOW(), last_ip = $1, user_agent = $2 WHERE id = $3', [req.ip || null, req.get('user-agent') || null, deviceId]);
    return next();
  } catch (error) { return next(error); }
}

module.exports = { requireApprovedDevice, requireDeviceEnrollmentToken };