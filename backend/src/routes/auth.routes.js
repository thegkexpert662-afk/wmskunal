const router = require('express').Router();

router.post('/login', (_req, res) => {
  res.status(501).json({
    error: {
      code: 'NOT_IMPLEMENTED',
      message: 'Authentication endpoint is reserved for the next backend phase.',
    },
  });
});

module.exports = router;
