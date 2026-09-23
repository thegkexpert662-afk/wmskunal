const pool = require('../config/db');

const OPERATIONAL_ROLES = new Set([
  'warehouse_manager','warehouse_supervisor','warehouse_operator',
  'warehouse_qc','gate_operator','inventory_user','dispatch_user',
]);

async function requireWarehouseAccess(req, res, next) {
  if (!req.user?.sub) return res.status(401).json({ error:{code:'UNAUTHENTICATED',message:'Authentication required.'} });
  if (req.user.role === 'master_admin') return res.status(403).json({ error:{code:'MASTER_OPERATIONAL_ACCESS_DENIED',message:'Master Admin cannot access operational business data.'} });

  try {
    const requested = req.params.warehouseId || req.body?.warehouseId || req.query?.warehouseId;
    if (!requested || !OPERATIONAL_ROLES.has(req.user.role)) return next();

    const result = await pool.query(
      'SELECT 1 FROM user_warehouses uw JOIN warehouses w ON w.id=uw.warehouse_id WHERE uw.user_id=$1 AND uw.warehouse_id=$2 AND w.company_id=$3 AND w.is_active=TRUE LIMIT 1',
      [req.user.sub, requested, req.user.companyId],
    );
    if (!result.rowCount) return res.status(403).json({error:{code:'WAREHOUSE_ACCESS_DENIED',message:'You are not assigned to this warehouse.'}});
    return next();
  } catch (error) { return next(error); }
}

async function getAssignedWarehouseIds(userId, companyId) {
  const result = await pool.query(
    'SELECT uw.warehouse_id FROM user_warehouses uw JOIN warehouses w ON w.id=uw.warehouse_id WHERE uw.user_id=$1 AND w.company_id=$2 AND w.is_active=TRUE',
    [userId, companyId],
  );
  return result.rows.map(r=>r.warehouse_id);
}

module.exports = { requireWarehouseAccess, getAssignedWarehouseIds, OPERATIONAL_ROLES };
