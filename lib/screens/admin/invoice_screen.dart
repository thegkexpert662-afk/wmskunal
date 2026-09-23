import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_widgets.dart';
import '../../services/invoice_service.dart';

class AdminInvoiceScreen extends StatefulWidget {
  const AdminInvoiceScreen({super.key});

  @override
  State<AdminInvoiceScreen> createState() => _AdminInvoiceScreenState();
}

class _AdminInvoiceScreenState extends State<AdminInvoiceScreen> {
  final api = InvoiceService.instance;
  final search = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  Map<String, dynamic>? selected;
  bool loading = true;
  String? error;
  String statusFilter = 'All';
  @override
  void initState() {
    super.initState();
    search.addListener(() { load(); });
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      if (mounted) setState(() { loading = true; error = null; });
      final rows = await api.list(
        search: search.text,
        status: statusFilter,
      );
      if (!mounted) return;
      setState(() {
        invoices = rows;
        if (selected != null) {
          final found = rows.where((x) => x['id'] == selected!['id']).toList();
          selected = found.isEmpty ? null : found.first;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openDetail(Map<String, dynamic> row) async {
    try {
      final d = await api.detail(row['id'].toString());
      if (mounted) setState(() => selected = d);
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> openPdf(String id) async {
    try {
      _message('Generating PDF...');
      final uri = await api.pdfDataUri(id);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('PDF could not be opened.');
      }
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> generateInvoice() async {
    final order = TextEditingController();
    final dispatch = TextEditingController();
    final cgst = TextEditingController(text: '0');
    final sgst = TextEditingController(text: '0');
    final igst = TextEditingController(text: '0');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Generate Invoice'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(order, 'Order ID *'),
                const SizedBox(height: 10),
                _field(dispatch, 'Dispatch ID (optional)'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(cgst, 'CGST %')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(sgst, 'SGST %')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(igst, 'IGST %')),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create Invoice')),
          ],
        ),
      );
      if (ok != true || order.text.trim().isEmpty) return;
      await api.create(
        orderId: order.text.trim(),
        dispatchId: dispatch.text.trim().isEmpty ? null : dispatch.text.trim(),
        cgstRate: double.tryParse(cgst.text) ?? 0,
        sgstRate: double.tryParse(sgst.text) ?? 0,
        igstRate: double.tryParse(igst.text) ?? 0,
      );
      _message('Invoice created successfully.');
      await load();
    } catch (e) {
      _message(e.toString());
    } finally {
      order.dispose();
      dispatch.dispose();
      cgst.dispose();
      sgst.dispose();
      igst.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Invoices',
      subtitle: 'Permanent invoice history • GST billing • company logo • PDF generated from database data.',
      actions: [
        OutlinedButton.icon(onPressed: load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: generateInvoice, icon: const Icon(Icons.add), label: const Text('Generate Invoice')),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    OutlinedButton(onPressed: load, child: const Text('Retry')),
                  ],
                ))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summary(),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 7, child: _invoiceTable()),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: _invoiceDetails()),
                    ]),
                  ],
                ),
    );
  }

  Widget _summary() {
    double total = 0;
    for (final x in invoices) {
      total += double.tryParse((x['total_amount'] ?? 0).toString()) ?? 0;
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _stat('Invoices', invoices.length.toString(), Icons.receipt_long_outlined),
        _stat('Issued', invoices.where((x) => x['status'] == 'issued').length.toString(), Icons.check_circle_outline),
        _stat('Cancelled', invoices.where((x) => x['status'] == 'cancelled').length.toString(), Icons.cancel_outlined),
        _stat('Value', '₹ ' + total.toStringAsFixed(2), Icons.currency_rupee_outlined),
      ],
    );
  }

  Widget _stat(String title, String value, IconData icon) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1769D5), size: 27),
        const SizedBox(width: 11),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF162B46))),
          ],
        )),
      ]),
    );
  }

  Widget _invoiceTable() {
    return Container(
      decoration: _box(),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(11),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
              width: 310,
              height: 40,
              child: TextField(
                controller: search,
                decoration: const InputDecoration(
                  hintText: 'Search invoice, client or order...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 150,
              height: 40,
              child: DropdownButtonFormField<String>(
                value: statusFilter,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const ['All', 'issued', 'cancelled']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                onChanged: (v) { if (v != null) { setState(() => statusFilter = v); load(); } },
              ),
            ),
          ]),
        ),
        const Divider(height: 1),
        invoices.isEmpty
            ? const Padding(padding: EdgeInsets.all(35), child: Text('No invoice records found.'))
            : HorizontalTableScroller(
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
                  columns: const [
                    DataColumn(label: Text('Invoice No')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Order')),
                    DataColumn(label: Text('Dispatch')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('PDF')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: invoices.map((x) => DataRow(cells: [
                    DataCell(Text((x['invoice_no'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                    DataCell(Text((x['invoice_date'] ?? '-').toString())),
                    DataCell(Text((x['client_name'] ?? '-').toString())),
                    DataCell(Text((x['order_no'] ?? '-').toString())),
                    DataCell(Text((x['dispatch_no'] ?? '-').toString())),
                    DataCell(Text('₹ ' + (x['total_amount'] ?? '0').toString())),
                    DataCell(_badge((x['status'] ?? '-').toString())),
                    DataCell(_badge(x['pdf_generated_at'] == null ? 'Not generated' : 'Ready')),
                    DataCell(Row(children: [
                      IconButton(tooltip: 'View', onPressed: () => openDetail(x), icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1769E8))),
                      IconButton(tooltip: 'PDF', onPressed: () => openPdf(x['id'].toString()), icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFE83C55))),
                    ])),
                  ])).toList(),
                ),
              ),
      ]),
    );
  }

  Widget _invoiceDetails() {
    if (selected == null) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: _box(),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 46, color: Color(0xFF9AA9BA)),
            SizedBox(height: 10),
            Text('Select an invoice to view complete details.'),
          ],
        ),
      );
    }

    final inv = selected!['invoice'] is Map
        ? Map<String, dynamic>.from(selected!['invoice'] as Map)
        : Map<String, dynamic>.from(selected!);
    final items = selected!['items'] is List
        ? (selected!['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if ((inv['company_logo_url_snapshot'] ?? '').toString().isNotEmpty)
              Image.network(inv['company_logo_url_snapshot'].toString(), width: 54, height: 54, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 40))
            else
              const Icon(Icons.business, size: 40, color: Color(0xFF1769D5)),
            const SizedBox(width: 10),
            Expanded(child: Text((inv['company_name_snapshot'] ?? '-').toString(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ]),
          const Divider(height: 25),
          _detail('Invoice No', (inv['invoice_no'] ?? '-').toString()),
          _detail('Invoice Date', (inv['invoice_date'] ?? '-').toString()),
          _detail('Client', (inv['client_name_snapshot'] ?? '-').toString()),
          _detail('Order', (inv['order_no'] ?? '-').toString()),
          _detail('Dispatch', (inv['dispatch_no'] ?? '-').toString()),
          _detail('Status', (inv['status'] ?? '-').toString()),
          const Divider(height: 25),
          const Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Text((item['product_name'] ?? item['description'] ?? '-').toString(), style: const TextStyle(fontSize: 11))),
              Text((item['quantity'] ?? 0).toString() + ' × ₹' + (item['rate'] ?? 0).toString(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          )),
          const Divider(height: 20),
          _detail('Taxable', '₹ ' + (inv['taxable_amount'] ?? 0).toString()),
          _detail('Discount', '₹ ' + (inv['discount_amount'] ?? 0).toString()),
          _detail('CGST', '₹ ' + (inv['cgst_amount'] ?? 0).toString()),
          _detail('SGST', '₹ ' + (inv['sgst_amount'] ?? 0).toString()),
          _detail('IGST', '₹ ' + (inv['igst_amount'] ?? 0).toString()),
          _detail('Grand Total', '₹ ' + (inv['total_amount'] ?? 0).toString()),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => openPdf(inv['id'].toString()),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('View / Generate PDF'),
          )),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: label.contains('%')
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF718096)))),
        Flexible(child: Text(value, textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF26384F)))),
      ]),
    );
  }

  Widget _amountRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: const Color(0xFF718096), fontWeight: bold ? FontWeight.w800 : FontWeight.normal))),
        Text(value, style: TextStyle(fontSize: 12, color: const Color(0xFF162B46), fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
      ]),
    );
  }

  Widget _drop(String value, List<String> values, ValueChanged<String> onChanged, String label) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9E1EA)), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          hint: Text(label),
          items: values.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (value) { if (value != null) onChanged(value); },
        ),
      ),
    );
  }

  Widget _badge(String text) {
    Color color = const Color(0xFF1769E8);
    if (<String>{'Paid', 'Ready', 'Sent'}.contains(text)) color = Colors.green.shade700;
    if (<String>{'Pending'}.contains(text)) color = Colors.orange.shade800;
    if (<String>{'Overdue'}.contains(text)) color = Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _page(String text, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Container(
        height: 28,
        constraints: const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? const Color(0xFF1769E8) : Colors.white, border: Border.all(color: const Color(0xFFDCE4ED)), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 10, color: active ? Colors.white : const Color(0xFF52657D), fontWeight: FontWeight.w700)),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8F1)),
      boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))],
    );
  }

  TextStyle _title(double size) => TextStyle(color: const Color(0xFF35465D), fontSize: size, fontWeight: FontWeight.w700);
  TextStyle _value(double size) => TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w900);

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
