const router = require('express').Router();
const { z } = require('zod');
const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

const createSchema = z.object({
  orderId: z.string().uuid(),
  dispatchId: z.string().uuid().optional(),
  invoiceDate: z.string().date().optional(),
  discountAmount: z.coerce.number().min(0).default(0),
  cgstRate: z.coerce.number().min(0).max(100).default(0),
  sgstRate: z.coerce.number().min(0).max(100).default(0),
  igstRate: z.coerce.number().min(0).max(100).default(0),
  paymentTerms: z.string().trim().max(500).optional(),
  dueDate: z.string().date().optional(),
});

const statusSchema = z.object({
  status: z.enum(['issued', 'cancelled']),
});

async function assigned(req) {
  return getAssignedWarehouseIds(req.user.sub, req.tenant.companyId);
}

function scopeFor(ids, params, alias = 'o') {
  if (!ids.length) return '';
  params.push(ids);
  return ` AND ${alias}.warehouse_id = ANY($${params.length}::uuid[])`;
}

async function accessibleInvoice(req, id, db = pool, forUpdate = false) {
  const ids = await assigned(req);
  const params = [id, req.tenant.companyId];
  let scope = scopeFor(ids, params, 'o');
  if (req.user.role === 'client') {
    params.push(req.user.clientId);
    scope += ` AND i.client_id=$${params.length}`;
  }
  return db.query(
    `SELECT i.*, c.name client_name, c.client_code,
            o.order_no, o.warehouse_id, w.code warehouse_code, w.name warehouse_name,
            d.dispatch_no
     FROM invoices i
     JOIN clients c ON c.id=i.client_id
     LEFT JOIN orders o ON o.id=i.order_id
     LEFT JOIN warehouses w ON w.id=o.warehouse_id
     LEFT JOIN dispatch d ON d.id=i.dispatch_id
     WHERE i.id=$1 AND i.company_id=$2${scope}
     ${forUpdate ? 'FOR UPDATE OF i' : ''}
     LIMIT 1`,
    params,
  );
}

router.get('/', requirePermission('invoice.read'), async (req, res, next) => {
  try {
    const ids = await assigned(req);
    const params = [req.tenant.companyId];
    let scope = scopeFor(ids, params, 'o');
    if (req.user.role === 'client') {
      params.push(req.user.clientId);
      scope += ` AND i.client_id=$${params.length}`;
    }
    if (req.query.search) {
      params.push(`%${String(req.query.search).trim()}%`);
      scope += ` AND (i.invoice_no ILIKE $${params.length} OR c.name ILIKE $${params.length} OR COALESCE(o.order_no,'') ILIKE $${params.length})`;
    }
    if (req.query.status) {
      params.push(String(req.query.status));
      scope += ` AND i.status=$${params.length}`;
    }
    if (req.query.from) {
      params.push(String(req.query.from));
      scope += ` AND i.invoice_date >= $${params.length}::date`;
    }
    if (req.query.to) {
      params.push(String(req.query.to));
      scope += ` AND i.invoice_date <= $${params.length}::date`;
    }
    const result = await pool.query(
      `SELECT i.id,i.invoice_no,i.invoice_date,i.status,i.taxable_amount,i.discount_amount,
              i.cgst_amount,i.sgst_amount,i.igst_amount,i.total_amount,i.pdf_path,i.pdf_generated_at,
              i.email_status,i.client_id,c.name client_name,c.client_code,
              o.order_no,o.warehouse_id,w.code warehouse_code,w.name warehouse_name,
              d.dispatch_no
       FROM invoices i
       JOIN clients c ON c.id=i.client_id
       LEFT JOIN orders o ON o.id=i.order_id
       LEFT JOIN warehouses w ON w.id=o.warehouse_id
       LEFT JOIN dispatch d ON d.id=i.dispatch_id
       WHERE i.company_id=$1${scope}
       ORDER BY i.invoice_date DESC,i.created_at DESC
       LIMIT 500`,
      params,
    );
    res.json({ invoices: result.rows });
  } catch (e) { next(e); }
});

router.get('/:id', requirePermission('invoice.read'), async (req, res, next) => {
  try {
    const result = await accessibleInvoice(req, req.params.id);
    if (!result.rowCount) return res.status(404).json({ error: { code: 'INVOICE_NOT_FOUND', message: 'Invoice not found.' } });
    const items = await pool.query(
      `SELECT ii.*,p.sku,p.name product_name
       FROM invoice_items ii
       LEFT JOIN products p ON p.id=ii.product_id
       WHERE ii.invoice_id=$1
       ORDER BY ii.id`,
      [req.params.id],
    );
    res.json({ invoice: result.rows[0], items: items.rows });
  } catch (e) { next(e); }
});

router.post('/', requirePermission('invoice.create'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = createSchema.parse(req.body);
    await db.query('BEGIN');

    const ids = await assigned(req);
    const params = [input.orderId, req.tenant.companyId];
    const scope = scopeFor(ids, params, 'o');
    const orderResult = await db.query(
      `SELECT o.*,c.name client_name,c.client_code,c.gstin client_gstin,c.address client_address,
              c.email client_email,c.mobile client_mobile,
              co.name company_name,co.logo_url,co.address company_address,co.gstin company_gstin,
              co.email company_email,co.mobile company_mobile
       FROM orders o
       JOIN clients c ON c.id=o.client_id
       JOIN companies co ON co.id=o.company_id
       WHERE o.id=$1 AND o.company_id=$2${scope}
       ${req.user.role === 'client' ? ` AND o.client_id=$${params.length + 1}` : ''}
       FOR UPDATE OF o`,
      req.user.role === 'client' ? [...params, req.user.clientId] : params,
    );
    if (!orderResult.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'ORDER_NOT_FOUND', message: 'Order not found or outside access.' } });
    }
    const order = orderResult.rows[0];

    let dispatch = null;
    if (input.dispatchId) {
      const d = await db.query(
        `SELECT * FROM dispatch WHERE id=$1 AND company_id=$2 AND order_id=$3 FOR UPDATE`,
        [input.dispatchId, req.tenant.companyId, input.orderId],
      );
      if (!d.rowCount) {
        await db.query('ROLLBACK');
        return res.status(400).json({ error: { code: 'DISPATCH_NOT_FOUND', message: 'Dispatch does not belong to this order.' } });
      }
      dispatch = d.rows[0];
    }

    const existing = await db.query(
      `SELECT id,invoice_no FROM invoices
       WHERE company_id=$1 AND order_id=$2 AND status<>'cancelled'
       LIMIT 1 FOR UPDATE`,
      [req.tenant.companyId, input.orderId],
    );
    if (existing.rowCount) {
      await db.query('ROLLBACK');
      return res.status(409).json({ error: { code: 'INVOICE_EXISTS', message: 'An active invoice already exists for this order.', invoiceId: existing.rows[0].id, invoiceNo: existing.rows[0].invoice_no } });
    }

    const itemQuery = input.dispatchId
      ? `SELECT oi.id order_item_id,oi.product_id,oi.ordered_qty quantity,p.name product_name,
                p.sku,p.hsn_code,p.uom,p.rate,p.description
         FROM dispatch_items di
         JOIN order_items oi ON oi.id=di.order_item_id
         JOIN products p ON p.id=oi.product_id
         WHERE di.dispatch_id=$1
         ORDER BY p.name`
      : `SELECT oi.id order_item_id,oi.product_id,oi.ordered_qty quantity,p.name product_name,
                p.sku,p.hsn_code,p.uom,p.rate,p.description
         FROM order_items oi
         JOIN products p ON p.id=oi.product_id
         WHERE oi.order_id=$1
         ORDER BY p.name`;
    const itemResult = await db.query(itemQuery, [input.dispatchId || input.orderId]);
    if (!itemResult.rowCount) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'NO_INVOICE_ITEMS', message: 'Order has no invoiceable items.' } });
    }

    const discount = Number(input.discountAmount || 0);
    let gross = 0;
    for (const item of itemResult.rows) gross += Number(item.quantity) * Number(item.rate || 0);
    const taxable = Math.max(0, gross - discount);
    const cgst = Number((taxable * Number(input.cgstRate || 0) / 100).toFixed(2));
    const sgst = Number((taxable * Number(input.sgstRate || 0) / 100).toFixed(2));
    const igst = Number((taxable * Number(input.igstRate || 0) / 100).toFixed(2));
    const total = Number((taxable + cgst + sgst + igst).toFixed(2));
    const invoiceDate = input.invoiceDate || new Date().toISOString().slice(0, 10);
    const year = invoiceDate.slice(0, 4);
    const invoiceNo = `INV-${year}-${Date.now().toString().slice(-8)}`;

    const invoice = await db.query(
      `INSERT INTO invoices(
         company_id,client_id,order_id,dispatch_id,invoice_no,invoice_date,status,
         taxable_amount,discount_amount,cgst_amount,sgst_amount,igst_amount,total_amount,
         payment_terms,due_date,
         company_name_snapshot,company_logo_url_snapshot,company_address_snapshot,company_gstin_snapshot,company_email_snapshot,company_mobile_snapshot,
         client_name_snapshot,client_address_snapshot,client_gstin_snapshot,client_email_snapshot,client_mobile_snapshot,
         created_by,updated_at
       ) VALUES($1,$2,$3,$4,$5,$6,'issued',$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27)
       RETURNING *`,
      [
        req.tenant.companyId,order.client_id,order.id,input.dispatchId || null,invoiceNo,invoiceDate,
        taxable,discount,cgst,sgst,igst,total,input.paymentTerms || null,input.dueDate || null,
        order.company_name,order.logo_url,order.company_address,order.company_gstin,order.company_email,order.company_mobile,
        order.client_name,order.client_address,order.client_gstin,order.client_email,order.client_mobile,
        req.user.sub,new Date(),
      ],
    );

    for (const item of itemResult.rows) {
      const lineGross = Number(item.quantity) * Number(item.rate || 0);
      const lineShare = gross > 0 ? lineGross / gross : 0;
      const lineDiscount = Number((discount * lineShare).toFixed(2));
      const lineTaxable = Math.max(0, lineGross - lineDiscount);
      const lineCgst = Number((lineTaxable * Number(input.cgstRate || 0) / 100).toFixed(2));
      const lineSgst = Number((lineTaxable * Number(input.sgstRate || 0) / 100).toFixed(2));
      const lineIgst = Number((lineTaxable * Number(input.igstRate || 0) / 100).toFixed(2));
      const lineTotal = Number((lineTaxable + lineCgst + lineSgst + lineIgst).toFixed(2));
      await db.query(
        `INSERT INTO invoice_items(
          invoice_id,product_id,description,hsn_code,uom,quantity,weight,rate,
          discount_amount,taxable_amount,cgst_amount,sgst_amount,igst_amount,line_total
        ) VALUES($1,$2,$3,$4,$5,$6,0,$7,$8,$9,$10,$11,$12,$13)`,
        [invoice.rows[0].id,item.product_id,item.product_name || item.description || item.sku,item.hsn_code,item.uom,item.quantity,item.rate || 0,lineDiscount,lineTaxable,lineCgst,lineSgst,lineIgst,lineTotal],
      );
    }

    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,ip_address,user_agent,metadata)
       VALUES($1,$2,'INVOICE_CREATED','invoice',$3,$4,$5,$6::jsonb)`,
      [req.tenant.companyId,req.user.sub,invoice.rows[0].id,req.ip || null,req.get('user-agent') || null,
       JSON.stringify({invoiceNo,orderId:order.id,orderNo:order.order_no,dispatchId:input.dispatchId || null,totalAmount:total})],
    );

    await db.query('COMMIT');
    res.status(201).json({ invoice: invoice.rows[0] });
  } catch (e) {
    await db.query('ROLLBACK').catch(() => {});
    if (e.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid invoice request.' } });
    if (e.code === '23505') return res.status(409).json({ error: { code: 'INVOICE_EXISTS', message: 'Invoice number already exists.' } });
    next(e);
  } finally { db.release(); }
});

router.patch('/:id/status', requirePermission('invoice.manage'), async (req, res, next) => {
  const db = await pool.connect();
  try {
    const input = statusSchema.parse(req.body);
    await db.query('BEGIN');
    const result = await accessibleInvoice(req, req.params.id, db, true);
    if (!result.rowCount) {
      await db.query('ROLLBACK');
      return res.status(404).json({ error: { code: 'INVOICE_NOT_FOUND', message: 'Invoice not found.' } });
    }
    const invoice = result.rows[0];
    if (invoice.status === 'cancelled' || (input.status === 'cancelled' && invoice.status !== 'issued')) {
      await db.query('ROLLBACK');
      return res.status(400).json({ error: { code: 'INVALID_INVOICE_STATUS', message: 'Invalid invoice status change.' } });
    }
    const updated = await db.query(
      `UPDATE invoices SET status=$1,updated_at=NOW() WHERE id=$2 RETURNING *`,
      [input.status, invoice.id],
    );
    await db.query(
      `INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata)
       VALUES($1,$2,$3,'invoice',$4,$5::jsonb)`,
      [req.tenant.companyId,req.user.sub,`INVOICE_STATUS_${input.status.toUpperCase()}`,invoice.id,JSON.stringify({from:invoice.status,to:input.status})],
    );
    await db.query('COMMIT');
    res.json({ invoice: updated.rows[0] });
  } catch (e) {
    await db.query('ROLLBACK').catch(() => {});
    if (e.name === 'ZodError') return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid invoice status.' } });
    next(e);
  } finally { db.release(); }
});

async function generatePdf(invoice, items, outputPath) {
  await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
  return new Promise(async (resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 42 });
    const stream = fs.createWriteStream(outputPath);
    stream.on('finish', resolve);
    stream.on('error', reject);
    doc.pipe(stream);

    if (invoice.company_logo_url_snapshot) {
      try {
        const response = await fetch(invoice.company_logo_url_snapshot);
        if (response.ok) {
          const buffer = Buffer.from(await response.arrayBuffer());
          doc.image(buffer, 42, 38, { fit: [75, 55] });
        }
      } catch (_) {}
    }

    doc.fontSize(18).font('Helvetica-Bold').text(invoice.company_name_snapshot || 'Company', 125, 42);
    doc.fontSize(9).font('Helvetica').text(invoice.company_address_snapshot || '', 125, 65, { width: 250 });
    doc.text(`GSTIN: ${invoice.company_gstin_snapshot || '-'}`, 125, 82);
    doc.text(`Email: ${invoice.company_email_snapshot || '-'}  Mobile: ${invoice.company_mobile_snapshot || '-'}`, 125, 96);
    doc.fontSize(20).font('Helvetica-Bold').text('TAX INVOICE', 390, 45);
    doc.fontSize(10).font('Helvetica').text(`Invoice No: ${invoice.invoice_no}`, 390, 75);
    doc.text(`Invoice Date: ${invoice.invoice_date}`, 390, 90);
    doc.moveTo(42, 125).lineTo(553, 125).stroke();

    doc.fontSize(10).font('Helvetica-Bold').text('BILL TO', 42, 140);
    doc.font('Helvetica').text(invoice.client_name_snapshot || '-', 42, 156);
    doc.text(invoice.client_address_snapshot || '-', 42, 171, { width: 240 });
    doc.text(`GSTIN: ${invoice.client_gstin_snapshot || '-'}`, 42, 203);

    let y = 235;
    const cols = [42, 205, 285, 350, 425, 500];
    doc.font('Helvetica-Bold').fontSize(9);
    ['Product','Qty','Rate','Taxable','GST','Amount'].forEach((h, i) => doc.text(h, cols[i], y, { width: i === 0 ? 155 : 65 }));
    y += 18;
    doc.font('Helvetica').fontSize(8);
    for (const item of items) {
      doc.text(item.description || '-', cols[0], y, { width: 155 });
      doc.text(Number(item.quantity).toFixed(2), cols[1], y);
      doc.text(Number(item.rate).toFixed(2), cols[2], y);
      doc.text(Number(item.taxable_amount).toFixed(2), cols[3], y);
      const gst = Number(item.cgst_amount) + Number(item.sgst_amount) + Number(item.igst_amount);
      doc.text(gst.toFixed(2), cols[4], y);
      doc.text(Number(item.line_total).toFixed(2), cols[5], y);
      y += 18;
      if (y > 690) { doc.addPage(); y = 50; }
    }
    y += 10;
    doc.font('Helvetica-Bold').fontSize(10);
    doc.text(`Taxable Amount: ${Number(invoice.taxable_amount).toFixed(2)}`, 330, y);
    y += 16;
    doc.text(`Discount: ${Number(invoice.discount_amount).toFixed(2)}`, 330, y);
    y += 16;
    doc.text(`CGST: ${Number(invoice.cgst_amount).toFixed(2)}`, 330, y);
    y += 16;
    doc.text(`SGST: ${Number(invoice.sgst_amount).toFixed(2)}`, 330, y);
    y += 16;
    doc.text(`IGST: ${Number(invoice.igst_amount).toFixed(2)}`, 330, y);
    y += 18;
    doc.fontSize(13).text(`Grand Total: ${Number(invoice.total_amount).toFixed(2)}`, 330, y);
    y += 35;
    doc.fontSize(9).font('Helvetica').text(`Payment Terms: ${invoice.payment_terms || '-'}`, 42, y);
    doc.text(`Order: ${invoice.order_no || '-'}    Dispatch: ${invoice.dispatch_no || '-'}`, 42, y + 16);
    doc.text('This is a system generated invoice.', 42, 770);

    doc.end();
  });
}

router.get('/:id/pdf', requirePermission('invoice.read'), async (req, res, next) => {
  try {
    const result = await accessibleInvoice(req, req.params.id);
    if (!result.rowCount) return res.status(404).json({ error: { code: 'INVOICE_NOT_FOUND', message: 'Invoice not found.' } });
    const items = await pool.query('SELECT * FROM invoice_items WHERE invoice_id=$1 ORDER BY id', [req.params.id]);
    const storageDir = path.resolve(process.env.INVOICE_STORAGE_DIR || path.join(process.cwd(), 'storage', 'invoices'));
    const filename = `${result.rows[0].invoice_no.replace(/[^a-zA-Z0-9_-]/g, '_')}.pdf`;
    const filePath = path.join(storageDir, filename);
    if (!fs.existsSync(filePath)) {
      await generatePdf(result.rows[0], items.rows, filePath);
      await pool.query('UPDATE invoices SET pdf_path=$1,pdf_generated_at=NOW(),updated_at=NOW() WHERE id=$2', [filePath, req.params.id]);
    }
    res.download(filePath, filename);
  } catch (e) { next(e); }
});

module.exports = router;
