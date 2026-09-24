const router = require('express').Router();

const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requireCompanyModule } = require('../middleware/company');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getErpConnector } = require('../services/erp_connector');

router.use(requireAuth, requireApprovedDevice, requireTenantContext, requireCompanyModule('grn'));

router.get('/purchase-invoices/:invoiceNo', requirePermission('grn.read'), async (req, res, next) => {
  try {
    const invoiceNo = decodeURIComponent(req.params.invoiceNo || '').trim();
    if (!invoiceNo) {
      return res.status(400).json({
        error: { code: 'INVOICE_NUMBER_REQUIRED', message: 'Supplier invoice number is required.' },
      });
    }

    const connector = getErpConnector(req.tenant);
    const invoice = await connector.getPurchaseInvoice(invoiceNo, req.tenant);

    return res.json({
      data: {
        ...invoice,
        source: (process.env.ERP_CONNECTOR || 'mock').trim().toLowerCase(),
      },
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
