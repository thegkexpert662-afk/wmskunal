import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AdminDispatchScreen extends StatefulWidget {
  const AdminDispatchScreen({super.key});

  @override
  State<AdminDispatchScreen> createState() => _AdminDispatchScreenState();
}

class _AdminDispatchScreenState extends State<AdminDispatchScreen> {
  final search = TextEditingController();
  String warehouse = 'All';
  String status = 'All';

  final dispatches = const [
    ['DSP-7018', 'ORD-10284', 'ABC Industries', 'Main Warehouse', 'MH04AB1234', 'LR-90081', '16 Sep 2026', 'Ready', '₹ 2,45,600'],
    ['DSP-7017', 'ORD-10283', 'Metro Retail', 'Ankleshwar WH', 'MH43CD2211', 'LR-90080', '16 Sep 2026', 'In Transit', '₹ 1,20,500'],
    ['DSP-7016', 'ORD-10282', 'Prime Traders', 'Vilayat Warehouse', 'GJ16XY7821', 'LR-90079', '15 Sep 2026', 'Dispatched', '₹ 3,10,000'],
    ['DSP-7015', 'ORD-10281', 'Global Parts', 'Main Warehouse', 'MH14EF5555', 'LR-90078', '15 Sep 2026', 'Delivered', '₹ 1,50,000'],
    ['DSP-7014', 'ORD-10280', 'Shree Ram Suppliers', 'Delhi Warehouse', 'DL01GH6622', 'LR-90077', '14 Sep 2026', 'Pending', '₹ 1,75,250'],
    ['DSP-7013', 'ORD-10279', 'Reliable Packaging', 'Ankleshwar WH', 'GJ05JK4433', 'LR-90076', '14 Sep 2026', 'Dispatched', '₹ 2,20,000'],
    ['DSP-7012', 'ORD-10278', 'Om Plastics', 'Vilayat Warehouse', 'GJ16LM8822', 'LR-90075', '13 Sep 2026', 'Delivered', '₹ 85,600'],
    ['DSP-7011', 'ORD-10277', 'JK Traders', 'Main Warehouse', 'MH12NP3399', 'LR-90074', '13 Sep 2026', 'Cancelled', '₹ 4,10,000'],
  ];

  List<List<String>> get filtered => dispatches.where((r) {
    final q = search.text.toLowerCase().trim();
    return (q.isEmpty || r.any((v) => v.toLowerCase().contains(q))) &&
        (warehouse == 'All' || r[3] == warehouse) &&
        (status == 'All' || r[7] == status);
  }).toList();

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
    final compact = MediaQuery.sizeOf(context).width < 1100;

    return ScreenFrame(
      title: 'Outward / Dispatch',
      subtitle: 'Manage orders, dispatch confirmation, transporter and gate-out workflow.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _message('Dispatch report exported successfully.'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _message('Create Dispatch opened.'),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Create Dispatch'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stats(compact),
          const SizedBox(height: 16),
          if (compact) ...[
            _table(),
            const SizedBox(height: 14),
            _details(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _table()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _details()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stats(bool compact) {
    final data = [
      ['Total Dispatches', '125', 'All Time', Icons.local_shipping_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)],
      ['Ready to Dispatch', '18', 'Today', Icons.inventory_2_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['In Transit', '42', 'Currently', Icons.route_outlined, const Color(0xFF7046D8), const Color(0xFFF0EAFF)],
      ['Delivered', '96', 'This Month', Icons.check_circle_outline, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['Total Dispatch Value', '₹ 48,75,650', 'All Dispatches', Icons.currency_rupee_rounded, const Color(0xFFE28C00), const Color(0xFFFFF3DE)],
    ];

    final cards = data
        .map((d) => _statCard(
              d[0] as String,
              d[1] as String,
              d[2] as String,
              d[3] as IconData,
              d[4] as Color,
              d[5] as Color,
            ))
        .toList();

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

  Widget _statCard(
    String title,
    String value,
    String sub,
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
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _title(11)),
                const SizedBox(height: 3),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: _title(22)),
                ),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF7A889A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(11),
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
                      hintText: 'Search by dispatch, order, client or vehicle...',
                      hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8491A2)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
                      ),
                    ),
                  ),
                ),
                _dropdown('Warehouse', warehouse, ['All', 'Main Warehouse', 'Ankleshwar WH', 'Vilayat Warehouse', 'Delhi Warehouse'], (v) => setState(() => warehouse = v!)),
                _dropdown('Status', status, ['All', 'Ready', 'In Transit', 'Dispatched', 'Delivered', 'Pending', 'Cancelled'], (v) => setState(() => status = v!)),
                OutlinedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 43,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 54,
              columnSpacing: 21,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Dispatch ID')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Vehicle')),
                DataColumn(label: Text('LR No.')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Value')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(filtered.length, (i) {
                final r = filtered[i];
                return DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(r[1])),
                  DataCell(Text(r[2])),
                  DataCell(Text(r[3])),
                  DataCell(Text(r[4])),
                  DataCell(Text(r[5])),
                  DataCell(Text(r[6])),
                  DataCell(_status(r[7])),
                  DataCell(Text(r[8])),
                  DataCell(Row(children: [
                    IconButton(onPressed: () => _message('Viewing ${r[0]}'), icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17)),
                    IconButton(onPressed: () => _message('Editing ${r[0]}'), icon: const Icon(Icons.edit_outlined, color: Color(0xFF1769E8), size: 17)),
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
                Text('Showing 1 to ${filtered.length} of 125 entries', style: const TextStyle(fontSize: 10, color: Color(0xFF748196))),
                const Spacer(),
                _page('Previous'),
                _page('1', active: true),
                _page('2'),
                _page('3'),
                _page('4'),
                _page('5'),
                _page('…'),
                _page('13'),
                _page('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text('Dispatch Details', style: _title(14)), const Spacer(), const Icon(Icons.close, size: 18, color: Color(0xFF7D899A))]),
          const SizedBox(height: 14),
          Row(children: [
            Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF1769E8), size: 25)),
            const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DSP-7018', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF162B46))), SizedBox(height: 3), Text('ORD-10284', style: TextStyle(fontSize: 10, color: Color(0xFF748196)))])),
            _status('Ready'),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _detail('Client', 'ABC Industries', Icons.person_outline),
          _detail('Warehouse', 'Main Warehouse', Icons.warehouse_outlined),
          _detail('Vehicle No.', 'MH04AB1234', Icons.local_shipping_outlined),
          _detail('Transporter', 'ABC Logistics', Icons.business_outlined),
          _detail('LR No.', 'LR-90081', Icons.receipt_long_outlined),
          _detail('Dispatch Date', '16 Sep 2026', Icons.calendar_today_outlined),
          _detail('Total Items', '8', Icons.inventory_2_outlined),
          _detail('Total Quantity', '120', Icons.numbers_outlined),
          _detail('Total Value', '₹ 2,45,600', Icons.currency_rupee_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: const Color(0xFFF7FAFD), borderRadius: BorderRadius.circular(9)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Dispatch Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF26384F))), SizedBox(height: 9), LinearProgressIndicator(value: .72, minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(8))), SizedBox(height: 6), Text('Ready for gate-out', style: TextStyle(fontSize: 9, color: Color(0xFF748196)))]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _message('Gate-out opened.'), icon: const Icon(Icons.output_outlined, size: 16), label: const Text('Gate Out'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: () => _message('Invoice opened.'), icon: const Icon(Icons.receipt_long_outlined, size: 16), label: const Text('Invoice'))),
          ]),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFF65758A)),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF68778B)))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF26384F)))),
        ]),
      );

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => Container(
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

  Widget _status(String value) {
    final Color text;
    final Color background;
    switch (value) {
      case 'Delivered':
        text = const Color(0xFF14894E); background = const Color(0xFFE4F7EC); break;
      case 'Ready':
        text = const Color(0xFF1769E8); background = const Color(0xFFEAF2FF); break;
      case 'In Transit':
      case 'Dispatched':
        text = const Color(0xFF7046D8); background = const Color(0xFFF0EAFF); break;
      case 'Pending':
        text = const Color(0xFFE28C00); background = const Color(0xFFFFF0D8); break;
      default:
        text = const Color(0xFFD92F4B); background = const Color(0xFFFFE5EA);
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(color: text, fontSize: 8, fontWeight: FontWeight.w800)));
  }

  Widget _page(String text, {bool active = false}) => Container(
        margin: const EdgeInsets.only(left: 4),
        height: 30,
        constraints: const BoxConstraints(minWidth: 30),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(color: active ? const Color(0xFF1769E8) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF))),
        child: Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.w700)),
      );

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1)), boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))]);
  TextStyle _title(double size) => TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w800);
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
