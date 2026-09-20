function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user?.role || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: 'You do not have permission for this operation.' },
      });
    }
    return next();
  };
}

module.exports = { requireRole };
