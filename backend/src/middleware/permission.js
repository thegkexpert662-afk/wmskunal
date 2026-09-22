const pool = require('../config/db');

function requirePermission(permissionKey) {
  return async (req, res, next) => {
    if (!req.user?.sub || !req.user?.role) {
      return res.status(401).json({
        error: { code: 'UNAUTHENTICATED', message: 'Authentication required.' },
      });
    }

    try {
      const result = await pool.query(
        `SELECT 1
         FROM role_permissions rp
         JOIN permissions p ON p.id = rp.permission_id
         WHERE rp.role = $1
           AND p.permission_key = $2
         LIMIT 1`,
        [req.user.role, permissionKey],
      );

      if (result.rowCount === 0) {
        return res.status(403).json({
          error: {
            code: 'PERMISSION_DENIED',
            message: 'You do not have permission for this operation.',
          },
        });
      }

      return next();
    } catch (error) {
      return next(error);
    }
  };
}

module.exports = { requirePermission };
