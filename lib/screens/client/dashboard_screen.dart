import 'package:flutter/material.dart';
import '../common_widgets.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  String orderStatus = 'All';

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Client Portal',
      subtitle: 'Secure client workspace for catalogue, orders, dispatches and invoices.',
      actions: [
        FilledButton.icon(
          onPressed: () => _message('Place Order opened.'),
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Place Order'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryCards(compact),
              const SizedBox(height: 16),
              if (compact)
                Column(children: [
                  _profileCard(),
                  const SizedBox(height: 14),
                  _quickActions(),
                  const SizedBox(height: 14),
                  _recentOrders(),
                ])
              else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _profileCard()),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: _quickActions()),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: _recentOrders()),
                ]),
              const SizedBox(height: 16),
              _ordersTable(),
              const SizedBox(height: 16),
              _invoicesTable(),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCards(bool compact) {
    final cards = <Widget>[
      _summary('Open Orders', '08', 'Awaiting processing', Icons.shopping_bag_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _summary('Processing', '05', 'Currently in process', Icons.sync_outlined, const Color(0xFFE59A00), const Color(0xFFFFF3DB)),
      _summary('Dispatched', '12', 'On the way', Icons.local_shipping_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _summary('Invoices', '24', 'Available invoices', Icons.receipt_long_outlined, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
    ];
    if (compact) {
      return GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cards);
    }
    return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i != cards.length - 1) const SizedBox(width: 12)]]);
  }

  Widget _summary(String title, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 27)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF65758A))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF8290A2))),
        ])),
      ]),
    );
  }

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1)), boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))]);

  Widget _panel(String title, Widget child) => Container(padding: const EdgeInsets.all(15), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF162B46))), const SizedBox(height: 10), child]));

  Widget _profileCard() => _panel('Client Account', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)), child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business_outlined, color: Color(0xFF1769E8), size: 25)),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ABC Industries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))), SizedBox(height: 3), Text('CL-001 • Brand A', style: TextStyle(fontSize: 9, color: Color(0xFF718096)))])),
      _statusChip('Active'),
    ])),
    const SizedBox(height: 9),
    _info('Contact', 'Admin User', Icons.person_outline),
    _info('Email', 'admin@abc.com', Icons.email_outlined),
    _info('Warehouse', 'WH-A', Icons.warehouse_outlined),
    _info('Last Login', 'Today, 09:18', Icons.schedule_outlined),
  ]));

  Widget _quickActions() => _panel('Quick Actions', Column(children: [
    _action(Icons.add_shopping_cart_outlined, 'Place New Order', 'Create a new material order', const Color(0xFF1769E8), () => _message('Place Order opened.')),
    _action(Icons.inventory_2_outlined, 'Product Catalogue', 'Browse available products and stock rules', const Color(0xFF16A05D), () => _message('Catalogue opened.')),
    _action(Icons.local_shipping_outlined, 'Track Dispatch', 'Check current dispatch status', const Color(0xFFE59A00), () => _message('Dispatch tracking opened.')),
    _action(Icons.receipt_long_outlined, 'View Invoices', 'Open billing and invoice history', const Color(0xFF7447D8), () => _message('Invoices opened.')),
  ]));

  Widget _action(IconData icon, String title, String sub, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 21)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF26384E))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF7A889A)))])),
    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9AA6B5)),
  ])));

  Widget _recentOrders() => _panel('Recent Orders', Column(children: [
    _orderRow('ORD-10284', '04 items • 580 qty', 'Processing', const Color(0xFFE59A00)),
    _orderRow('ORD-10270', '08 items • 1,240 qty', 'Dispatched', const Color(0xFF1769E8)),
    _orderRow('ORD-10255', '03 items • 760 qty', 'Delivered', const Color(0xFF16A05D)),
    _orderRow('ORD-10241', '06 items • 940 qty', 'Delivered', const Color(0xFF16A05D)),
  ]));

  Widget _orderRow(String id, String sub, String statusText, Color color) => Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(id, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF26384E))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 8, color: Color(0xFF7A889A)))])), _smallStatus(statusText, color)]));

  Widget _ordersTable() {
    final rows = [
      ['ORD-10284', '16 Sep 2026', '04', '580', '₹2,84,500', 'Processing'],
      ['ORD-10270', '12 Sep 2026', '08', '1,240', '₹1,18,200', 'Dispatched'],
      ['ORD-10255', '08 Sep 2026', '03', '760', '₹86,900', 'Delivered'],
      ['ORD-10241', '05 Sep 2026', '06', '940', '₹1,42,750', 'Delivered'],
    ];
    final filtered = orderStatus == 'All' ? rows : rows.where((row) => row[5] == orderStatus).toList();
    final dataRows = filtered.map<DataRow>((row) {
      final cells = <DataCell>[];
      for (var index = 0; index < row.length; index++) {
        if (index == 5) {
          cells.add(DataCell(_smallStatus(row[index], _statusColor(row[index]))));
        } else {
          cells.add(DataCell(Text(
            row[index],
            style: TextStyle(
              fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF26384F),
            ),
          )));
        }
      }
      cells.add(DataCell(IconButton(
        onPressed: () => _message('Viewing ${row[0]}'),
        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
        tooltip: 'View',
      )));
      return DataRow(cells: cells);
    }).toList();

    return _panel('My Orders', _tableContent(const ['Order ID', 'Date', 'Items', 'Qty', 'Amount', 'Status', 'Action'], dataRows, 'Showing ${filtered.length} of 4 entries', _ordersFilter()));
  }

  Widget _ordersFilter() => _dropdown(orderStatus, const ['All', 'Processing', 'Dispatched', 'Delivered'], (value) => setState(() => orderStatus = value ?? 'All'));

  Widget _invoicesTable() {
    final rows = [
      ['INV-2026-081', 'ORD-10284', '₹2,84,500', '16 Sep 2026', 'Ready', 'Sent'],
      ['INV-2026-075', 'ORD-10270', '₹1,18,200', '12 Sep 2026', 'Ready', 'Sent'],
      ['INV-2026-069', 'ORD-10255', '₹86,900', '08 Sep 2026', 'Ready', 'Sent'],
      ['INV-2026-061', 'ORD-10241', '₹1,42,750', '05 Sep 2026', 'Ready', 'Pending'],
    ];
    final dataRows = rows.map<DataRow>((row) {
      final cells = <DataCell>[];
      for (var index = 0; index < row.length; index++) {
        if (index == 4 || index == 5) {
          final color = row[index] == 'Pending' ? const Color(0xFFE59A00) : const Color(0xFF16A05D);
          cells.add(DataCell(_smallStatus(row[index], color)));
        } else {
          cells.add(DataCell(Text(
            row[index],
            style: TextStyle(
              fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF26384F),
            ),
          )));
        }
      }
      cells.add(DataCell(IconButton(
        onPressed: () => _message('Opening ${row[0]}'),
        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
        tooltip: 'View',
      )));
      return DataRow(cells: cells);
    }).toList();

    return _panel('My Invoices', _tableContent(const ['Invoice', 'Order', 'Amount', 'Date', 'PDF', 'Email', 'Action'], dataRows, 'Showing ${rows.length} of 4 entries', OutlinedButton.icon(onPressed: () => _message('Invoice export started.'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export'))));
  }

  Widget _tableContent(List<String> headers, List<DataRow> rows, String footer, Widget action) {
    return Column(children: [
      Row(children: [const Spacer(), action]),
      const SizedBox(height: 8),
      const Divider(height: 1),
      LayoutBuilder(
        builder: (context, tableConstraints) {
          return HorizontalTableScroller(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
              child: DataTable(
                headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 58,
          columnSpacing: 26,
          horizontalMargin: 18,
          headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF52657A)),
          dataTextStyle: const TextStyle(fontSize: 10, color: Color(0xFF33465B)),
          headingRowColor: const MaterialStatePropertyAll(Color(0xFFF7F9FC)),
          columns: headers.map((header) {
            final width = switch (header) {
              'Order ID' => 120.0,
              'Invoice' => 120.0,
              'Date' => 100.0,
              'Items' => 75.0,
              'Qty' => 85.0,
              'Amount' => 120.0,
              'Status' => 105.0,
              'PDF' => 75.0,
              'Email' => 80.0,
              'Action' => 95.0,
              'Order' => 110.0,
              _ => 110.0,
            };
            return DataColumn(
              columnWidth: FixedColumnWidth(width),
              label: Text(header),
            );
          }).toList(),
                rows: rows,
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Text(footer, style: const TextStyle(fontSize: 9, color: Color(0xFF718096))), const Spacer(), _pageButton('‹'), _pageButton('1', active: true), _pageButton('›')])),
    ]);
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 38,
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDCE4EE)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          style: const TextStyle(fontSize: 10, color: Color(0xFF42546A), fontWeight: FontWeight.w600),
          items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _pageButton(String text, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1769E8) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF63738A))),
    );
  }

  Widget _info(String title, String value, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, size: 15, color: const Color(0xFF748397)), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF748397))),), Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF293C53)))]));
  }

  Widget _statusChip(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE4F7EC), borderRadius: BorderRadius.circular(6)), child: Text(text, style: const TextStyle(color: Color(0xFF14894E), fontSize: 8, fontWeight: FontWeight.w800)));
  }

  Widget _smallStatus(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Processing':
        return const Color(0xFFE59A00);
      case 'Dispatched':
        return const Color(0xFF1769E8);
      default:
        return const Color(0xFF16A05D);
    }
  }
}
