const { z } = require('zod');

const purchaseInvoiceSchema = z.object({
  invoiceNo: z.string().trim().min(1).max(100),
  supplierName: z.string().trim().min(1).max(200),
  currency: z.string().trim().max(10).default('INR'),
  items: z.array(z.object({
    productCode: z.string().trim().min(1).max(100),
    description: z.string().trim().min(1).max(500),
    invoiceQty: z.number().positive(),
    uom: z.string().trim().min(1).max(30),
  })).min(1),
});

// Connector contract. Real ERP connectors will implement the same method later.
class ErpConnector {
  async getPurchaseInvoice(_invoiceNo, _context) {
    throw new Error('ERP connector is not configured.');
  }
}

// Temporary testing connector. It has no external network dependency.
class MockErpConnector extends ErpConnector {
  async getPurchaseInvoice(invoiceNo, context) {
    const normalized = invoiceNo.trim().toUpperCase();
    const invoices = {
      'INV-23456': {
        invoiceNo: 'INV-23456',
        supplierName: 'ABC Supplier',
        currency: 'INR',
        items: [
          { productCode: 'PROD-001', description: 'ABC Material', invoiceQty: 200, uom: 'KG' },
          { productCode: 'PROD-002', description: 'XYZ Material', invoiceQty: 50, uom: 'KG' },
          { productCode: 'PROD-003', description: 'DEF Material', invoiceQty: 100, uom: 'PCS' },
        ],
      },
      'INV-50': {
        invoiceNo: 'INV-50',
        supplierName: 'Demo Supplier',
        currency: 'INR',
        items: Array.from({ length: 50 }, (_, index) => ({
          productCode: 'PROD-' + String(index + 1).padStart(3, '0'),
          description: 'Demo Product ' + (index + 1),
          invoiceQty: index + 10,
          uom: 'KG',
        })),
      },
    };

    const invoice = invoices[normalized];
    if (!invoice) {
      const error = new Error('Purchase invoice not found in Mock ERP.');
      error.statusCode = 404;
      error.code = 'ERP_INVOICE_NOT_FOUND';
      throw error;
    }

    return purchaseInvoiceSchema.parse({ ...invoice, companyId: context.companyId });
  }
}

function getErpConnector(_context) {
  // Keep the selection behind one factory so a real SAP/Oracle/custom connector
  // can replace the mock connector without changing the GRN route.
  const connectorType = (process.env.ERP_CONNECTOR || 'mock').trim().toLowerCase();
  if (connectorType === 'mock') return new MockErpConnector();

  const error = new Error('Configured ERP connector is not implemented yet.');
  error.statusCode = 503;
  error.code = 'ERP_CONNECTOR_NOT_CONFIGURED';
  throw error;
}

module.exports = { ErpConnector, MockErpConnector, getErpConnector, purchaseInvoiceSchema };
