import 'package:flutter/material.dart';

import '../common_widgets.dart';

class AdminInvoiceScreen extends StatefulWidget {
  const AdminInvoiceScreen({super.key});

  @override
  State<AdminInvoiceScreen> createState() => _AdminInvoiceScreenState();
}

class _AdminInvoiceScreenState extends State<AdminInvoiceScreen> {
  String statusFilter = 'All';
  String clientFilter = 'All';
  String search = '';

  final List<Map<String, String>> invoices = const [
    {
      'invoice': 'INV-2026-081',
      'client': 'ABC Industries',
      'order': 'ORD-10284',
      'warehouse': 'Main Warehouse',
      'amount': '₹ 2,84,500',
      'date': '16-09-2026',
      'status': 'Paid',
      'pdf': 'Ready',
      'email': 'Sent',
    },
    {
      'invoice': 'INV-2026-080',
      'client': 'Metro Retail',
      'order': 'ORD-10283',
      'warehouse': 'Ankleshwar WH',
      'amount': '₹ 1,72,800',
      'date': '16-09-2026',
      'status': 'Pending',
      'pdf': 'Ready',
      'email': 'Sent',
    },
    {
      'invoice': 'INV-2026-079',
      'client': 'Prime Traders',
      'order': 'ORD-10282',
      'warehouse': 'Vilayat Warehouse',
      'amount': '₹ 98,400',
      'date': '15-09-2026',
      'status': 'Paid',
      'pdf': 'Ready',
      'email': 'Pending',
    },
    {
      'invoice': 'INV-2026-078',
      'client': 'Global Parts',
      'order': 'ORD-10281',
      'warehouse': 'Delhi Warehouse',
      'amount': '₹ 76,250',
      'date': '15-09-2026',
      'status': 'Overdue',
      'pdf': 'Ready',
      'email': 'Sent',
    },
    {
      'invoice': 'INV-2026-077',
      'client': 'National Fabrics',
      'order': 'ORD-10280',
      'warehouse': 'Mumbai Warehouse',
      'amount': '₹ 1,45,300',
      'date': '14-09-2026',
      'status': 'Paid',
      'pdf': 'Ready',
      'email': 'Sent',
    },
    {
      'invoice': 'INV-2026-076',
      'client': 'Shree Ram Suppliers',
      'order': 'ORD-10279',
      'warehouse': 'Main Warehouse',
      'amount': '₹ 2,20,000',
      'date': '13-09-2026',
      'status': 'Pending',
      'pdf': 'Ready',
      'email': 'Pending',
    },
  ];

  List<Map<String, String>> get filteredInvoices {
    final query = search.toLowerCase().trim();
    return invoices.where((invoice) {
      final matchesSearch = query.isEmpty ||
          invoice.values.any((value) => value.toLowerCase().contains(query));
      final matchesStatus =
          statusFilter == 'All' || invoice['status'] == statusFilter;
      final matchesClient =
          clientFilter == 'All' || invoice['client'] == clientFilter;
      return matchesSearch && matchesStatus && matchesClient;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1150;

    return ScreenFrame(
      title: 'Invoices',
      subtitle: 'Manage invoices, GST billing, PDFs and client notifications.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _message('Invoice records exported successfully.'),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Export'),
        ),
        FilledButton.icon(
          onPressed: () => _message('Generate Invoice selected.'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Generate Invoice'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summary(compact),
          const SizedBox(height: 16),
          if (compact) ...[
            _invoiceTable(),
            const SizedBox(height: 14),
            _invoiceDetails(filteredInvoices.isNotEmpty ? filteredInvoices.first : invoices.first),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _invoiceTable()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _invoiceDetails(filteredInvoices.isNotEmpty ? filteredInvoices.first : invoices.first)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summary(bool compact) {
    final cards = [
      _stat('Total Invoices', '248', 'All time', Icons.receipt_long_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _stat('This Month', '32', 'September 2026', Icons.calendar_month_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _stat('Pending', '08', 'Awaiting payment', Icons.schedule_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)),
      _stat('Overdue', '03', 'Payment overdue', Icons.warning_amber_rounded, const Color(0xFFE83C55), const Color(0xFFFFE9ED)),
      _stat('Total Value', '₹ 48,75,650', 'Current billing value', Icons.currency_rupee_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
    ];

    if (compact) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.25,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _stat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _title(11)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: _value(22)),
                ),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF738298), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceTable() {
    final rows = filteredInvoices;
    return Container(
      decoration: _box(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 300,
                  height: 40,
                  child: TextField(
                    onChanged: (value) => setState(() => search = value),
                    decoration: InputDecoration(
                      hintText: 'Search invoice, client or order...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                _drop(statusFilter, const ['All', 'Paid', 'Pending', 'Overdue'], (v) => setState(() => statusFilter = v), 'Status'),
                _drop(clientFilter, const ['All', 'ABC Industries', 'Metro Retail', 'Prime Traders', 'Global Parts'], (v) => setState(() => clientFilter = v), 'Client'),
                OutlinedButton.icon(
                  onPressed: () => _message('Invoice filters applied.'),
                  icon: const Icon(Icons.filter_alt_outlined, size: 17),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Color(0xFF43546A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFF26384F),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              headingRowHeight: 48,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              columnSpacing: 26,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Invoice No')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('PDF')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(rows.length, (index) {
                final invoice = rows[index];
                return DataRow(cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(invoice['invoice']!, style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(invoice['client']!)),
                  DataCell(Text(invoice['order']!)),
                  DataCell(Text(invoice['warehouse']!)),
                  DataCell(Text(invoice['amount']!)),
                  DataCell(Text(invoice['date']!)),
                  DataCell(_badge(invoice['status']!)),
                  DataCell(_badge(invoice['pdf']!)),
                  DataCell(_badge(invoice['email']!)),
                  DataCell(Row(children: [
                    IconButton(onPressed: () => _message('Viewing ${invoice['invoice']}'), tooltip: 'View', icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1769E8))),
                    IconButton(onPressed: () => _message('PDF download started.'), tooltip: 'Download PDF', icon: const Icon(Icons.download_outlined, size: 18, color: Color(0xFF1769E8))),
                  ])),
                ]);
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text('Showing 1 to ${rows.length} of 248 entries', style: const TextStyle(color: Color(0xFF718096), fontSize: 10)),
                const Spacer(),
                _page('Prev'), _page('1', active: true), _page('2'), _page('3'), _page('4'), _page('5'), _page('…'), _page('25'), _page('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceDetails(Map<String, String> invoice) {
    return Container(
      decoration: _box(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Invoice Details', style: _value(16))),
              const Icon(Icons.close, size: 18, color: Color(0xFF8190A2)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.receipt_long_outlined, color: Color(0xFF1769E8), size: 30),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(invoice['invoice']!, style: _value(15)),
                  const SizedBox(height: 3),
                  Text(invoice['client']!, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                ])),
                _badge(invoice['status']!),
              ]),
            ),
            const SizedBox(height: 16),
            _detail('Order ID', invoice['order']!, Icons.shopping_cart_outlined),
            _detail('Warehouse', invoice['warehouse']!, Icons.warehouse_outlined),
            _detail('Invoice Date', invoice['date']!, Icons.calendar_today_outlined),
            _detail('Amount', invoice['amount']!, Icons.currency_rupee_rounded),
            _detail('PDF Status', invoice['pdf']!, Icons.picture_as_pdf_outlined),
            _detail('Email Status', invoice['email']!, Icons.email_outlined),
            const Divider(height: 28),
            Text('Billing Summary', style: _value(14)),
            const SizedBox(height: 10),
            _amountRow('Taxable Amount', '₹ 2,50,000'),
            _amountRow('GST (18%)', '₹ 45,000'),
            _amountRow('Grand Total', invoice['amount']!, bold: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _message('PDF download started.'), icon: const Icon(Icons.download_outlined, size: 17), label: const Text('Download PDF'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: () => _message('Invoice email sent.'), icon: const Icon(Icons.send_outlined, size: 17), label: const Text('Send'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF72849A)),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF718096)))),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF26384F)))),
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
