const pool = require('../config/db');

function requireCompanyModule(moduleKey) {
  return async (req, res, next) => {
    if (req.user?.role === 'master_admin') {
      return res.status(403).json({
        error: { code: 'MASTER_OPERATIONAL_ACCESS_DENIED', message: 'Master Admin cannot access operational business modules.' },
      });
    }

    const companyId = req.user?.companyId;
    if (!companyId) {
      return res.status(403).json({
        error: { code: 'COMPANY_REQUIRED', message: 'Company context is required.' },
      });
    }

    try {
      const result = await pool.query(
        'SELECT 1 FROM company_modules WHERE company_id = $1 AND module_key = $2 AND is_enabled = TRUE',
        [companyId, moduleKey],
      );

      if (result.rowCount === 0) {
        return res.status(403).json({
          error: { code: 'MODULE_DISABLED', message: 'This module is not enabled for the company.' },
        });
      }

      return next();
    } catch (error) {
      return next(error);
    }
  };
}

module.exports = { requireCompanyModule };
