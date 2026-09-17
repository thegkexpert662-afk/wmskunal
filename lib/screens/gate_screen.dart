import 'package:flutter/material.dart';
import 'common_widgets.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  final TextEditingController search = TextEditingController();
  String type = 'All';
  String status = 'All';

  final List<List<String>> records = const [
    ['GT-0081', 'MH04AB1234', 'ABC Industries', 'Main Warehouse', 'Inward', '09:12 AM', 'Inside', 'Rakesh Sharma'],
    ['GT-0080', 'GJ16XY7821', 'Prime Traders', 'Ankleshwar WH', 'Outward', '10:30 AM', 'Exited', 'Mohit Patel'],
    ['GT-0079', 'MH43CD2211', 'Metro Retail', 'Main Warehouse', 'Inward', '11:05 AM', 'Inside', 'Suresh Kumar'],
    ['GT-0078', 'GJ05KL9910', 'Global Parts', 'Vilayat Warehouse', 'Outward', '12:15 PM', 'Pending', 'Amit Verma'],
    ['GT-0077', 'MH14EF5555', 'ABC Industries', 'Delhi Warehouse', 'Inward', '01:20 PM', 'Inside', 'Neha Singh'],
    ['GT-0076', 'MH12PQ8822', 'Metro Retail', 'Mumbai Warehouse', 'Outward', '02:05 PM', 'Exited', 'Vikas Yadav'],
    ['GT-0075', 'GJ01RT4421', 'Prime Traders', 'Ankleshwar WH', 'Inward', '02:40 PM', 'Inside', 'Sohan Patel'],
    ['GT-0074', 'MH43CD9912', 'Global Parts', 'Main Warehouse', 'Outward', '03:15 PM', 'Pending', 'Rahul Mehta'],
  ];

  List<List<String>> get filteredRecords {
    final query = search.text.toLowerCase().trim();
    return records.where((record) {
      final matchesSearch = query.isEmpty || record.any(
        (value) => value.toLowerCase().contains(query),
      );
      final matchesType = type == 'All' || record[4] == type;
      final matchesStatus = status == 'All' || record[6] == status;
      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
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
      title: 'Gate In / Out',
      subtitle: 'Vehicle entry, exit and gate movement records.',
      actions: [
        FilledButton.icon(
          onPressed: () => _msg('Gate Entry form opened.'),
          icon: const Icon(Icons.add),
          label: const Text('Gate Entry'),
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
    final data = [
      ['Total Movements', '1,248', 'All Gate Records', Icons.swap_vert_circle_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)],
      ['Today In', '34', 'Vehicle Entries', Icons.login_rounded, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['Today Out', '28', 'Vehicle Exits', Icons.logout_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)],
      ['At Gate', '06', 'Currently Inside', Icons.local_shipping_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)],
      ['Pending', '04', 'Awaiting Action', Icons.pending_actions_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)],
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
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _bold(12)),
                const SizedBox(height: 3),
                Text(value, style: _bold(23)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF738298), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() {
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
      decoration: _box(),
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
      'Gate Movement Records',
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
              columnSpacing: 21,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Gate ID')),
                DataColumn(label: Text('Vehicle No')),
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(rows.length, (index) {
                final record = rows[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(record[0])),
                    DataCell(Text(record[1], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(record[2])),
                    DataCell(Text(record[3])),
                    DataCell(_typeChip(record[4])),
                    DataCell(Text(record[5])),
                    DataCell(_statusChip(record[6])),
                    DataCell(_view(record[0])),
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
                  'Showing 1 to ${rows.length} of 1,248 entries',
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
                ),
                const Spacer(),
                _page('Prev'),
                _page('1', true),
                _page('2'),
                _page('3'),
                _page('4'),
                _page('5'),
                _page('…'),
                _page('125'),
                _page('Next'),
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
            width: 310,
            height: 40,
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: 'Search vehicle, gate ID, client...',
                hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8290A2)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
                ),
              ),
            ),
          ),
          _drop(
            value: type,
            items: const ['All', 'Inward', 'Outward'],
            onChanged: (value) => setState(() => type = value ?? 'All'),
            label: 'Type',
          ),
          _drop(
            value: status,
            items: const ['All', 'Inside', 'Exited', 'Pending'],
            onChanged: (value) => setState(() => status = value ?? 'All'),
            label: 'Status',
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _msg('Gate records exported successfully.'),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Export'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drop({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Container(
      height: 40,
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDCE4EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF42546A),
            fontWeight: FontWeight.w600,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item == 'All' ? '$label: All' : item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _typeChip(String value) {
    final inward = value == 'Inward';
    final color = inward ? const Color(0xFF1769E8) : const Color(0xFF7447D8);
    final background = inward ? const Color(0xFFEAF2FF) : const Color(0xFFF0EAFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statusChip(String value) {
    final inside = value == 'Inside';
    final pending = value == 'Pending';
    final color = inside
        ? const Color(0xFF14894E)
        : pending
            ? const Color(0xFFE28C00)
            : const Color(0xFF1769E8);
    final background = inside
        ? const Color(0xFFE4F7EC)
        : pending
            ? const Color(0xFFFFF0D8)
            : const Color(0xFFEAF2FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _view(String id) {
    return IconButton(
      onPressed: () => _msg('Viewing gate record $id'),
      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
      tooltip: 'View',
    );
  }

  Widget _page(String text, [bool active = false]) {
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
          color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF),
        ),
      ),
      child: Text(
        text,
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
      'Gate Details',
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
                    Icons.local_shipping_outlined,
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
                        'MH04AB1234',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'GT-0081 • Inward',
                        style: TextStyle(fontSize: 9, color: Color(0xFF718096)),
                      ),
                    ],
                  ),
                ),
                _statusChip('Inside'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('Client', 'ABC Industries', Icons.business_outlined),
          _detail('Warehouse', 'Main Warehouse', Icons.warehouse_outlined),
          _detail('Driver', 'Rakesh Sharma', Icons.person_outline),
          _detail('Entry Time', '09:12 AM', Icons.schedule_outlined),
          _detail('Gate', 'Gate 01', Icons.sensor_door_outlined),
          _detail('Purpose', 'Material Receipt', Icons.inventory_2_outlined),
          const Divider(height: 22),
          const Text(
            'Movement Timeline',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF172A43)),
          ),
          const SizedBox(height: 10),
          _timeline('Gate Entry', '09:12 AM', true),
          _timeline('Vehicle Verified', '09:16 AM', true),
          _timeline('Dock Assigned', '09:20 AM', true),
          _timeline('GRN Pending', 'Waiting', false),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _msg('Gate record edited.'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _msg('Gate exit started.'),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Gate Out'),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF718096)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 9, color: Color(0xFF718096)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F)),
          ),
        ],
      ),
    );
  }

  Widget _timeline(String title, String time, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? const Color(0xFF16A05D) : const Color(0xFFB7C0CC),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 9, color: Color(0xFF45566C)),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 8, color: Color(0xFF78869A), fontWeight: FontWeight.w700),
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
