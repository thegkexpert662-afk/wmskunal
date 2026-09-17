import 'package:flutter/material.dart';

import 'common_widgets.dart';

class MaterialOutScreen extends StatefulWidget {
  const MaterialOutScreen({super.key});

  @override
  State<MaterialOutScreen> createState() => _MaterialOutScreenState();
}

class _MaterialOutScreenState extends State<MaterialOutScreen> {
  final TextEditingController search = TextEditingController();
  String status = 'All';

  final List<List<String>> records = const [
    ['MO-4008', 'ORD-10284', 'ABC Industries', 'Main Warehouse', '580', 'MH04AB1234', '16 Sep 2026', 'Approved'],
    ['MO-4007', 'ORD-10283', 'Metro Retail', 'Ankleshwar WH', '1,240', 'MH43CD2211', '16 Sep 2026', 'Ready'],
    ['MO-4006', 'ORD-10282', 'Prime Traders', 'Vilayat Warehouse', '760', 'GJ16XY7821', '15 Sep 2026', 'Dispatched'],
    ['MO-4005', 'ORD-10281', 'Global Parts', 'Main Warehouse', '420', '-', '15 Sep 2026', 'Pending'],
    ['MO-4004', 'ORD-10280', 'ABC Industries', 'Delhi Warehouse', '310', 'DL01EF4567', '14 Sep 2026', 'Approved'],
    ['MO-4003', 'ORD-10279', 'Metro Retail', 'Mumbai Warehouse', '680', 'MH01GH8899', '14 Sep 2026', 'Ready'],
    ['MO-4002', 'ORD-10278', 'Prime Traders', 'Ankleshwar WH', '950', 'GJ05JK3412', '13 Sep 2026', 'Pending'],
    ['MO-4001', 'ORD-10277', 'Global Parts', 'Main Warehouse', '220', 'MH12LM7788', '13 Sep 2026', 'Dispatched'],
  ];

  List<List<String>> get filteredRecords {
    final query = search.text.toLowerCase().trim();

    return records.where((record) {
      final matchesSearch = query.isEmpty ||
          record.any((value) => value.toLowerCase().contains(query));
      final matchesStatus = status == 'All' || record[7] == status;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    search.removeListener(_onSearchChanged);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1050;

    return ScreenFrame(
      title: 'Material Out',
      subtitle: 'Verify picked material and approve outward movement.',
      actions: [
        FilledButton.icon(
          onPressed: () => _msg('Material Out task created.'),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Create Material Out'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stats(compact),
          const SizedBox(height: 16),
          if (compact)
            Column(
              children: [
                _table(),
                const SizedBox(height: 14),
                _details(),
              ],
            )
          else
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
    final data = <List<Object>>[
      [
        'Total Material Out',
        '186',
        'All Outward Tasks',
        Icons.outbox_outlined,
        const Color(0xFF1769E8),
        const Color(0xFFEAF2FF),
      ],
      [
        'Pending',
        '24',
        'Awaiting Approval',
        Icons.pending_actions_outlined,
        const Color(0xFFE49A0A),
        const Color(0xFFFFF3D9),
      ],
      [
        'Ready',
        '31',
        'Ready for Dispatch',
        Icons.inventory_2_outlined,
        const Color(0xFF7447D8),
        const Color(0xFFF0EAFF),
      ],
      [
        'Approved',
        '18',
        'Approved for Outward',
        Icons.check_circle_outline,
        const Color(0xFF16A05D),
        const Color(0xFFE7F9EF),
      ],
      [
        'Dispatched',
        '113',
        'Material Dispatched',
        Icons.local_shipping_outlined,
        const Color(0xFF08A4A6),
        const Color(0xFFE5FAFA),
      ],
    ];

    final cards = data.map((item) {
      return _stat(
        item[0] as String,
        item[1] as String,
        item[2] as String,
        item[3] as IconData,
        item[4] as Color,
        item[5] as Color,
      );
    }).toList();

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
        for (int i = 0; i < cards.length; i++) ...[
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
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bold(12),
                ),
                const SizedBox(height: 3),
                Text(value, style: _bold(23)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF738298),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8F1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A18304F),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  TextStyle _bold(double size) {
    return TextStyle(
      color: const Color(0xFF162B46),
      fontSize: size,
      fontWeight: FontWeight.w800,
    );
  }

  Widget _panel(String title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _bold(14)),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }

  Widget _table() {
    final rows = filteredRecords;

    return _panel(
      'Material Out Records',
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 310,
                  height: 40,
                  child: TextField(
                    controller: search,
                    decoration: InputDecoration(
                      hintText: 'Search MO no, order, client, vehicle...',
                      hintStyle: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8290A2),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFDCE4EE),
                        ),
                      ),
                    ),
                  ),
                ),
                _statusDropdown(),
                OutlinedButton.icon(
                  onPressed: () => _msg('Material Out records filtered.'),
                  icon: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _msg('Material Out records exported.'),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 49,
              dataRowMaxHeight: 54,
              columnSpacing: 20,
              headingRowColor: const WidgetStatePropertyAll(
                Color(0xFFFAFBFD),
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('MO No')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Vehicle')),
                DataColumn(label: Text('Created')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(rows.length, (index) {
                final row = rows[index];

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(row[0])),
                    DataCell(
                      Text(
                        row[1],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(row[2])),
                    DataCell(Text(row[3])),
                    DataCell(Text(row[4])),
                    DataCell(Text(row[5])),
                    DataCell(Text(row[6])),
                    DataCell(_status(row[7])),
                    DataCell(
                      IconButton(
                        onPressed: () => _msg('Viewing ${row[0]}'),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF1769E8),
                          size: 17,
                        ),
                      ),
                    ),
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
                Text(
                  'Showing 1 to ${rows.length} of 186 entries',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                _page('Prev'),
                _page('1', true),
                _page('2'),
                _page('3'),
                _page('4'),
                _page('5'),
                _page('…'),
                _page('19'),
                _page('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDropdown() {
    const values = [
      'All',
      'Pending',
      'Ready',
      'Approved',
      'Dispatched',
    ];

    return Container(
      height: 40,
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDCE4EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF42546A),
            fontWeight: FontWeight.w600,
          ),
          items: values.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value == 'All' ? 'Status: All' : value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => status = value);
            }
          },
        ),
      ),
    );
  }

  Widget _status(String value) {
    final colors = <String, List<Color>>{
      'Pending': [
        const Color(0xFFFFF0D8),
        const Color(0xFFE28C00),
      ],
      'Ready': [
        const Color(0xFFEAF2FF),
        const Color(0xFF1769E8),
      ],
      'Approved': [
        const Color(0xFFE4F7EC),
        const Color(0xFF14894E),
      ],
      'Dispatched': [
        const Color(0xFFE5FAFA),
        const Color(0xFF08A4A6),
      ],
    };

    final colorPair = colors[value] ?? [
      const Color(0xFFF1F4F8),
      const Color(0xFF63738A),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorPair[0],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: colorPair[1],
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _page(String label, [bool active = false]) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      height: 30,
      constraints: const BoxConstraints(minWidth: 30),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1769E8) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? const Color(0xFF1769E8)
              : const Color(0xFFDDE5EF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF63738A),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _details() {
    return _panel(
      'Material Out Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.outbox_outlined,
                    color: Color(0xFF1769E8),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MO-4008',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172A43),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'ORD-10284 • 580 Qty',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                _status('Approved'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('Client', 'ABC Industries', Icons.business_outlined),
          _detail('Warehouse', 'Main Warehouse', Icons.warehouse_outlined),
          _detail('Vehicle', 'MH04AB1234', Icons.local_shipping_outlined),
          _detail('Total Quantity', '580', Icons.inventory_2_outlined),
          _detail('Packages', '24', Icons.all_inbox_outlined),
          _detail('Created On', '16 Sep 2026', Icons.calendar_today_outlined),
          _detail('Approved By', 'Admin User', Icons.person_outline),
          const Divider(height: 22),
          const Text(
            'Outward Progress',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172A43),
            ),
          ),
          const SizedBox(height: 10),
          const LinearProgressIndicator(
            value: 0.72,
            minHeight: 7,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 7),
          const Text(
            '72% processed • 18 of 24 packages completed',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _msg('Material Out task edited.'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _msg('Material Out approved.'),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF718096)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF718096),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF27394F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
