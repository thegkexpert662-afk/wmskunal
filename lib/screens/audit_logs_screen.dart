import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final search = TextEditingController();
  String resultFilter = 'All';
  String moduleFilter = 'All';

  final logs = const [
    ['AUD-1001', '19:32', 'Admin User', 'Orders', 'Accepted Order', 'ORD-10284', 'Success', 'Web'],
    ['AUD-1002', '18:55', 'Manager A', 'Inventory', 'Stock Transfer', 'TR-5012', 'Success', 'Web'],
    ['AUD-1003', '18:31', 'Client A1', 'Orders', 'Placed Order', 'ORD-10284', 'Success', 'Portal'],
    ['AUD-1004', '17:48', 'Admin User', 'Invoice', 'Generated PDF', 'INV-2026-081', 'Success', 'Web'],
    ['AUD-1005', '17:25', 'Manager B', 'Picking', 'Released Pick List', 'PK-2098', 'Success', 'Web'],
    ['AUD-1006', '16:40', 'Admin User', 'Users', 'Updated User Role', 'USR-0042', 'Success', 'Web'],
    ['AUD-1007', '15:58', 'Client A1', 'Orders', 'Cancelled Order', 'ORD-10276', 'Warning', 'Portal'],
    ['AUD-1008', '15:21', 'Manager A', 'Inventory', 'Stock Adjustment', 'ADJ-1044', 'Failed', 'Web'],
  ];

  List<List<String>> get filteredLogs {
    final q = search.text.toLowerCase().trim();
    return logs.where((r) {
      final matchesSearch = q.isEmpty || r.any((v) => v.toLowerCase().contains(q));
      final matchesResult = resultFilter == 'All' || r[6] == resultFilter;
      final matchesModule = moduleFilter == 'All' || r[3] == moduleFilter;
      return matchesSearch && matchesResult && matchesModule;
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
      title: 'Audit Logs',
      subtitle: 'Track important user, security and operational actions.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _msg('Audit logs exported successfully.'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export Logs'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stats(compact),
          const SizedBox(height: 16),
          if (compact)
            Column(children: [_table(), const SizedBox(height: 14), _details()])
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
      ['Total Events', '1,284', 'All Recorded', Icons.history_rounded, const Color(0xFF1769E8), const Color(0xFFEAF2FF)],
      ['Success', '1,246', '96.0% Events', Icons.check_circle_outline, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['Warnings', '26', 'Needs Review', Icons.warning_amber_rounded, const Color(0xFFE6A014), const Color(0xFFFFF5E1)],
      ['Failed', '12', 'Action Required', Icons.error_outline_rounded, const Color(0xFFE83C55), const Color(0xFFFFE9ED)],
      ['Today', '48', 'Events Today', Icons.today_outlined, const Color(0xFF7447D8), const Color(0xFFF0EAFF)],
    ];
    final cards = data
        .map((d) => _stat(d[0] as String, d[1] as String, d[2] as String, d[3] as IconData, d[4] as Color, d[5] as Color))
        .toList();
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _bold(12)),
                const SizedBox(height: 3),
                FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: _bold(23))),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF738298), fontSize: 10)),
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
      boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))],
    );
  }

  TextStyle _bold(double size) {
    return TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w800);
  }

  Widget _panel(String title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: _bold(14)), const SizedBox(height: 8), body],
      ),
    );
  }

  Widget _table() {
    return _panel(
      'Activity Log',
      Column(
        children: [
          _filters(),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 49,
              dataRowMaxHeight: 55,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Audit ID')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Module')),
                DataColumn(label: Text('Action')),
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Result')),
                DataColumn(label: Text('Source')),
                DataColumn(label: Text('View')),
              ],
              rows: List.generate(filteredLogs.length, (i) {
                final r = filteredLogs[i];
                return DataRow(
                  cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(r[1])),
                    DataCell(Text(r[2], style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(r[3])),
                    DataCell(Text(r[4])),
                    DataCell(Text(r[5])),
                    DataCell(_resultChip(r[6])),
                    DataCell(_sourceChip(r[7])),
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
                Text('Showing 1 to ${filteredLogs.length} of 1,284 entries', style: const TextStyle(color: Color(0xFF718096), fontSize: 10)),
                const Spacer(),
                _page('Prev'),
                _page('1', true),
                _page('2'),
                _page('3'),
                _page('4'),
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
            width: 320,
            height: 40,
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: 'Search user, action, reference...',
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
          _dropdown('Result', resultFilter, const ['All', 'Success', 'Warning', 'Failed'], (v) => setState(() => resultFilter = v)),
          _dropdown('Module', moduleFilter, const ['All', 'Orders', 'Inventory', 'Invoice', 'Picking', 'Users'], (v) => setState(() => moduleFilter = v)),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
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
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(fontSize: 10, color: Color(0xFF42546A), fontWeight: FontWeight.w600),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item == 'All' ? '$label: All' : item),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _resultChip(String value) {
    final success = value == 'Success';
    final warning = value == 'Warning';
    final color = success ? const Color(0xFF14894E) : warning ? const Color(0xFFE28C00) : const Color(0xFFD92F4B);
    final bg = success ? const Color(0xFFE4F7EC) : warning ? const Color(0xFFFFF0D8) : const Color(0xFFFFE5EA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }

  Widget _sourceChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF2F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: const TextStyle(color: Color(0xFF53657B), fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }

  Widget _view(String id) {
    return IconButton(
      onPressed: () => _msg('Viewing audit event $id'),
      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
      tooltip: 'View details',
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
        border: Border.all(color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF)),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _details() {
    return _panel(
      'Audit Event Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.security_outlined, color: Color(0xFF1769E8), size: 25),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AUD-1001', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
                      SizedBox(height: 3),
                      Text('Admin User • Orders • Success', style: TextStyle(fontSize: 9, color: Color(0xFF718096))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('User', 'Admin User', Icons.person_outline),
          _detail('Module', 'Orders', Icons.inventory_2_outlined),
          _detail('Action', 'Accepted Order', Icons.task_alt_outlined),
          _detail('Reference', 'ORD-10284', Icons.receipt_long_outlined),
          _detail('Time', '19:32 • 16 Sep 2026', Icons.schedule_outlined),
          _detail('Source', 'Web', Icons.language_outlined),
          const Divider(height: 22),
          const Text('Security note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF162B46))),
          const SizedBox(height: 5),
          const Text('Audit records should remain append-only and protected from normal user edits.', style: TextStyle(fontSize: 9, height: 1.4, color: Color(0xFF718096))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _msg('Full audit event opened.'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View Full Event'),
            ),
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
          Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF718096)))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F))),),
        ],
      ),
    );
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
