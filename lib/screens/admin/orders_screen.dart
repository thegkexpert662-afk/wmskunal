import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final search = TextEditingController();
  String status = 'All';
  String client = 'All';

  final orders = const [
    ['ORD-10284', 'ABC Industries', '04', '580', '16 Sep 2026', '17 Sep 2026', 'Processing', '₹ 12,50,000'],
    ['ORD-10283', 'Metro Retail', '08', '1,240', '16 Sep 2026', '18 Sep 2026', 'Picking', '₹ 8,75,000'],
    ['ORD-10282', 'Prime Traders', '03', '760', '15 Sep 2026', '17 Sep 2026', 'Dispatched', '₹ 6,40,000'],
    ['ORD-10281', 'Global Parts', '06', '420', '15 Sep 2026', '19 Sep 2026', 'Pending', '₹ 4,20,000'],
    ['ORD-10280', 'ABC Industries', '07', '950', '14 Sep 2026', '16 Sep 2026', 'Ready', '₹ 9,15,000'],
    ['ORD-10279', 'Metro Retail', '05', '315', '14 Sep 2026', '18 Sep 2026', 'Processing', '₹ 3,80,000'],
    ['ORD-10278', 'Prime Traders', '09', '1,580', '13 Sep 2026', '16 Sep 2026', 'Delivered', '₹ 15,60,000'],
    ['ORD-10277', 'Global Parts', '04', '280', '13 Sep 2026', '17 Sep 2026', 'Cancelled', '₹ 2,75,000'],
  ];

  List<List<String>> get filteredOrders {
    final q = search.text.toLowerCase().trim();
    return orders.where((r) {
      return (q.isEmpty || r.any((v) => v.toLowerCase().contains(q))) &&
          (status == 'All' || r[6] == status) &&
          (client == 'All' || r[1] == client);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1050;
    return ScreenFrame(
      title: 'Orders',
      subtitle: 'Manage client orders from acceptance through dispatch.',
      actions: [
        FilledButton.icon(
          onPressed: () => _message('New Order form opened.'),
          icon: const Icon(Icons.add),
          label: const Text('New Order'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summary(compact),
          const SizedBox(height: 16),
          if (compact)
            Column(children: [_ordersTable(), const SizedBox(height: 14), _orderDetails()])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _ordersTable()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _orderDetails()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summary(bool compact) {
    final cards = [
      _stat('Total Orders', '1,248', 'All Orders', Icons.shopping_cart_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _stat('New Orders', '12', 'Awaiting Processing', Icons.fiber_new_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
      _stat('Processing', '24', 'Currently Processing', Icons.sync_rounded, const Color(0xFFE6A014), const Color(0xFFFFF5E1)),
      _stat('Ready', '08', 'Ready for Dispatch', Icons.inventory_2_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _stat('Dispatched', '36', 'This Month', Icons.local_shipping_outlined, const Color(0xFF08A8C7), const Color(0xFFE6F8FC)),
    ];
    if (compact) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
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

  Widget _stat(String title, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _bold(11)),
                const SizedBox(height: 3),
                Text(value, style: _bold(23)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF758398))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordersTable() {
    return _panel(
      'Client Orders',
      Column(
        children: [
          _filters(),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 49,
              dataRowMaxHeight: 54,
              columnSpacing: 20,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Order Date')),
                DataColumn(label: Text('Required')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Order Value')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(filteredOrders.length, (i) {
                final r = filteredOrders[i];
                return DataRow(
                  cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(r[1])),
                    DataCell(Text(r[2])),
                    DataCell(Text(r[3])),
                    DataCell(Text(r[4])),
                    DataCell(Text(r[5])),
                    DataCell(_statusChip(r[6])),
                    DataCell(Text(r[7])),
                    DataCell(_view(r[0])),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text('Showing 1 to ${filteredOrders.length} of 1,248 entries', style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                const Spacer(),
                _page('Prev'), _page('1', true), _page('2'), _page('3'), _page('4'), _page('5'), _page('…'), _page('125'), _page('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 300,
            height: 40,
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: 'Search order ID, client or item...',
                hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8290A2)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDCE4EE))),
              ),
            ),
          ),
          _drop(client, const ['All', 'ABC Industries', 'Metro Retail', 'Prime Traders', 'Global Parts'], (v) => setState(() => client = v!), 'Client'),
          _drop(status, const ['All', 'Pending', 'Processing', 'Picking', 'Ready', 'Dispatched', 'Delivered', 'Cancelled'], (v) => setState(() => status = v!), 'Status'),
          OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.filter_alt_outlined, size: 16), label: const Text('Filter'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
          OutlinedButton.icon(onPressed: () => _message('Orders exported successfully.'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
        ],
      ),
    );
  }

  Widget _drop(String value, List<String> values, ValueChanged<String?> onChanged, String label) {
    return Container(
      height: 40,
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDCE4EE)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(fontSize: 10, color: Color(0xFF42546A), fontWeight: FontWeight.w600),
          items: values.map((v) => DropdownMenuItem(value: v, child: Text(v == 'All' ? '$label: All' : v, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _orderDetails() {
    return _panel(
      'Order Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1769E8), size: 25)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ORD-10284', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))), SizedBox(height: 3), Text('ABC Industries', style: TextStyle(fontSize: 9, color: Color(0xFF718096)))])),
                _statusChip('Processing'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('Order Date', '16 Sep 2026', Icons.calendar_today_outlined),
          _detail('Required Date', '17 Sep 2026', Icons.event_available_outlined),
          _detail('Warehouse', 'Main Warehouse', Icons.warehouse_outlined),
          _detail('Items', '4 Items', Icons.inventory_2_outlined),
          _detail('Total Quantity', '580', Icons.numbers_outlined),
          _detail('Order Value', '₹ 12,50,000', Icons.currency_rupee_rounded),
          const Divider(height: 22),
          const Text('Order Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
          const SizedBox(height: 10),
          _progress('Order Accepted', '16 Sep • 09:15 AM', true),
          _progress('Processing', '16 Sep • 10:20 AM', true),
          _progress('Picking', 'In Progress', false),
          _progress('Ready for Dispatch', 'Pending', false),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _message('Order details opened.'), icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('View'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _message('Picking started.'), icon: const Icon(Icons.play_arrow_rounded, size: 17), label: const Text('Process')))]),
        ],
      ),
    );
  }

  Widget _detail(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [Icon(icon, size: 16, color: const Color(0xFF718096)), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF718096))),), Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F)))]),
    );
  }

  Widget _progress(String title, String time, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: done ? const Color(0xFF16A05D) : const Color(0xFFB7C0CC)), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF45566C)))), Text(time, style: const TextStyle(fontSize: 8, color: Color(0xFF78869A), fontWeight: FontWeight.w700))]),
    );
  }

  Widget _statusChip(String value) {
    final colors = <String, List<Color>>{
      'Pending': [const Color(0xFFFFF0D8), const Color(0xFFE28C00)],
      'Processing': [const Color(0xFFEAF2FF), const Color(0xFF1769E8)],
      'Picking': [const Color(0xFFF0EAFF), const Color(0xFF7447D8)],
      'Ready': [const Color(0xFFE4F7EC), const Color(0xFF14894E)],
      'Dispatched': [const Color(0xFFE6F8FC), const Color(0xFF078AA5)],
      'Delivered': [const Color(0xFFE4F7EC), const Color(0xFF14894E)],
      'Cancelled': [const Color(0xFFFFE5EA), const Color(0xFFD92F4B)],
    };
    final c = colors[value] ?? [const Color(0xFFF0F3F7), const Color(0xFF66758A)];
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(color: c[1], fontSize: 8, fontWeight: FontWeight.w800)));
  }

  Widget _view(String id) => IconButton(onPressed: () => _message('Viewing $id'), icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17), tooltip: 'View Order');

  Widget _page(String value, [bool active = false]) => Container(margin: const EdgeInsets.only(left: 4), height: 30, constraints: const BoxConstraints(minWidth: 30), alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 7), decoration: BoxDecoration(color: active ? const Color(0xFF1769E8) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF))), child: Text(value, style: TextStyle(color: active ? Colors.white : const Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.w700)));

  Widget _panel(String title, Widget child) => Container(padding: const EdgeInsets.all(15), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _bold(14)), const SizedBox(height: 8), child]));

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1)), boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))]);

  TextStyle _bold(double size) => TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w800);

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
