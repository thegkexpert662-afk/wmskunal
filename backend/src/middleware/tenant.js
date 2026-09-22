const pool = require('../config/db');

async function requireTenantContext(req, res, next) {
  if (!req.user?.sub || !req.user?.role) {
    return res.status(401).json({
      error: { code: 'UNAUTHENTICATED', message: 'Authentication required.' },
    });
  }

  if (req.user.role === 'master_admin') {
    return res.status(403).json({
      error: {
        code: 'MASTER_OPERATIONAL_ACCESS_DENIED',
        message: 'Master Admin cannot access operational business data.',
      },
    });
  }

  if (!req.user.companyId) {
    return res.status(403).json({
      error: {
        code: 'COMPANY_REQUIRED',
        message: 'Company context is required.',
      },
    });
  }

  try {
    const result = await pool.query(
      `SELECT u.id, u.company_id, u.client_id, u.role, u.is_active,
              c.is_active AS client_is_active
       FROM users u
       LEFT JOIN clients c ON c.id = u.client_id
       WHERE u.id = $1
       LIMIT 1`,
      [req.user.sub],
    );

    if (result.rowCount === 0 || !result.rows[0].is_active) {
      return res.status(403).json({
        error: { code: 'USER_INACTIVE', message: 'This user is no longer active.' },
      });
    }

    const currentUser = result.rows[0];

    if (currentUser.role !== req.user.role ||
        currentUser.company_id !== req.user.companyId) {
      return res.status(403).json({
        error: {
          code: 'AUTHORIZATION_CONTEXT_CHANGED',
          message: 'Your authorization context has changed. Please sign in again.',
        },
      });
    }

    if (currentUser.role === 'client') {
      if (!currentUser.client_id || currentUser.client_id !== req.user.clientId) {
        return res.status(403).json({
          error: {
            code: 'CLIENT_CONTEXT_REQUIRED',
            message: 'Valid client context is required.',
          },
        });
      }

      if (currentUser.client_is_active === false) {
        return res.status(403).json({
          error: {
            code: 'CLIENT_INACTIVE',
            message: 'This client account is inactive.',
          },
        });
      }
    }

    req.tenant = {
      companyId: currentUser.company_id,
      clientId: currentUser.client_id || null,
    };

    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = { requireTenantContext };
