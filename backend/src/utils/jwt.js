const jwt = require('jsonwebtoken');

function signAccessToken(user, deviceId = null) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      companyId: user.company_id || null,
      clientId: user.client_id || null,
      deviceId,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '15m' },
  );
}

module.exports = { signAccessToken };