import 'package:flutter/material.dart';

import '../common_widgets.dart';

class AdminPickingScreen extends StatefulWidget {
  const AdminPickingScreen({super.key});

  @override
  State<AdminPickingScreen> createState() => _AdminPickingScreenState();
}

class _AdminPickingScreenState extends State<AdminPickingScreen> {
  final searchController = TextEditingController();
  String status = 'All';
  String warehouse = 'All';

  final records = const [
    ['PICK-5012', 'ORD-10284', 'ABC Industries', 'Main Warehouse', '12', 'Rahul Sharma', 'In Progress'],
    ['PICK-5011', 'ORD-10283', 'Metro Retail', 'Ankleshwar WH', '18', 'Amit Patel', 'Assigned'],
    ['PICK-5010', 'ORD-10282', 'Prime Traders', 'Vilayat Warehouse', '08', 'Suresh Kumar', 'Completed'],
    ['PICK-5009', 'ORD-10281', 'Global Parts', 'Main Warehouse', '11', '-', 'Pending'],
    ['PICK-5008', 'ORD-10280', 'ABC Industries', 'Delhi Warehouse', '15', 'Neha Singh', 'In Progress'],
    ['PICK-5007', 'ORD-10279', 'Metro Retail', 'Mumbai Warehouse', '07', 'Vikas Yadav', 'Completed'],
    ['PICK-5006', 'ORD-10278', 'Prime Traders', 'Ankleshwar WH', '21', 'Sohan Patel', 'Assigned'],
    ['PICK-5005', 'ORD-10277', 'Global Parts', 'Main Warehouse', '09', '-', 'Pending'],
  ];

  List<List<String>> get filteredRecords {
    final query = searchController.text.trim().toLowerCase();
    return records.where((row) {
      final matchesSearch = query.isEmpty || row.any((value) => value.toLowerCase().contains(query));
      final matchesStatus = status == 'All' || row[6] == status;
      final matchesWarehouse = warehouse == 'All' || row[3] == warehouse;
      return matchesSearch && matchesStatus && matchesWarehouse;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    searchController.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 1100;
    return ScreenFrame(
      title: 'Picking',
      subtitle: 'Create, assign and execute warehouse picking tasks.',
      actions: [
        FilledButton.icon(
          onPressed: () => _message('Create Pick List opened.'),
          icon: const Icon(Icons.add),
          label: const Text('Create Pick List'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryCards(narrow),
          const SizedBox(height: 16),
          if (narrow)
            Column(children: [_recordsCard(), const SizedBox(height: 14), _detailsCard()])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _recordsCard()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _detailsCard()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryCards(bool narrow) {
    final cards = [
      _summary('Total Pick Lists', '125', 'All Pick Tasks', Icons.inventory_2_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _summary('Pending', '18', 'Waiting Assignment', Icons.pending_actions_outlined, const Color(0xFFE29A08), const Color(0xFFFFF4DE)),
      _summary('Assigned', '32', 'Ready to Pick', Icons.person_pin_circle_outlined, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
      _summary('In Progress', '31', 'Currently Picking', Icons.local_shipping_outlined, const Color(0xFF0C91A6), const Color(0xFFE5F8FB)),
      _summary('Completed', '44', 'Successfully Picked', Icons.check_circle_outline, const Color(0xFF16A05D), const Color(0xFFE5F8EE)),
    ];
    if (narrow) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
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

  Widget _summary(String title, String value, String subtitle, IconData icon, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF516176))),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF7A8798))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordsCard() {
    return _panel(
      'Picking Tasks',
      Column(
        children: [
          _filters(),
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
                DataColumn(columnWidth: const FixedColumnWidth(50), label: Text('#')),
                DataColumn(columnWidth: const FixedColumnWidth(110), label: Text('Pick ID')),
                DataColumn(columnWidth: const FixedColumnWidth(110), label: Text('Order ID')),
                DataColumn(columnWidth: const FixedColumnWidth(160), label: Text('Client')),
                DataColumn(columnWidth: const FixedColumnWidth(140), label: Text('Warehouse')),
                DataColumn(columnWidth: const FixedColumnWidth(75), label: Text('Lines')),
                DataColumn(columnWidth: const FixedColumnWidth(110), label: Text('Picker')),
                DataColumn(columnWidth: const FixedColumnWidth(105), label: Text('Status')),
                DataColumn(columnWidth: const FixedColumnWidth(90), label: Text('Actions')),
              ],
              rows: List.generate(filteredRecords.length, (index) {
                final row = filteredRecords[index];
                return DataRow(cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(row[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(row[1])),
                  DataCell(Text(row[2])),
                  DataCell(Text(row[3])),
                  DataCell(Text(row[4])),
                  DataCell(Text(row[5])),
                  DataCell(_statusChip(row[6])),
                  DataCell(_actionButton(row[0])),
                ]);
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text('Showing 1 to ${filteredRecords.length} of 125 entries', style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                const Spacer(),
                _pageButton('Prev'),
                _pageButton('1', active: true),
                _pageButton('2'),
                _pageButton('3'),
                _pageButton('4'),
                _pageButton('5'),
                _pageButton('…'),
                _pageButton('13'),
                _pageButton('Next'),
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search Pick ID, order, client...',
                hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8290A2)),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDCE4EE))),
              ),
            ),
          ),
          _dropdown('Status', status, const ['All', 'Pending', 'Assigned', 'In Progress', 'Completed'], (value) => setState(() => status = value!)),
          _dropdown('Warehouse', warehouse, const ['All', 'Main Warehouse', 'Ankleshwar WH', 'Vilayat Warehouse', 'Delhi Warehouse', 'Mumbai Warehouse'], (value) => setState(() => warehouse = value!)),
          OutlinedButton.icon(
            onPressed: () => _message('Picking records filtered.'),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
          ),
          OutlinedButton.icon(
            onPressed: () => _message('Picking records exported.'),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) {
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
          items: values.map((item) => DropdownMenuItem(value: item, child: Text(item == 'All' ? '$label: All' : item, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statusChip(String value) {
    final Color color;
    final Color background;
    switch (value) {
      case 'Completed':
        color = const Color(0xFF14894E);
        background = const Color(0xFFE4F7EC);
        break;
      case 'In Progress':
        color = const Color(0xFF0B8498);
        background = const Color(0xFFE4F7FA);
        break;
      case 'Assigned':
        color = const Color(0xFF7041D1);
        background = const Color(0xFFF0E9FF);
        break;
      default:
        color = const Color(0xFFE18A00);
        background = const Color(0xFFFFF0D7);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }

  Widget _actionButton(String id) {
    return IconButton(
      tooltip: 'View',
      onPressed: () => _message('Viewing $id'),
      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
    );
  }

  Widget _pageButton(String text, {bool active = false}) {
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

  Widget _detailsCard() {
    return _panel(
      'Pick Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1769E8), size: 25)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PICK-5012', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))), SizedBox(height: 3), Text('ORD-10284 • 12 Lines', style: TextStyle(fontSize: 9, color: Color(0xFF718096)))])),
                _statusChip('In Progress'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('Client', 'ABC Industries', Icons.business_outlined),
          _detail('Warehouse', 'Main Warehouse', Icons.warehouse_outlined),
          _detail('Picker', 'Rahul Sharma', Icons.person_outline),
          _detail('Priority', 'High', Icons.priority_high_outlined),
          _detail('Created', '16 Sep 2026', Icons.calendar_today_outlined),
          _detail('Total Lines', '12', Icons.format_list_numbered),
          _detail('Picked Qty', '82 / 120', Icons.inventory_outlined),
          const Divider(height: 22),
          const Text('Picking Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: const LinearProgressIndicator(value: 0.68, minHeight: 9, backgroundColor: Color(0xFFE8EEF5), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1769E8)))),
          const SizedBox(height: 6),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('68% completed', style: TextStyle(fontSize: 9, color: Color(0xFF1769E8), fontWeight: FontWeight.w700)), Text('82 / 120 Qty', style: TextStyle(fontSize: 9, color: Color(0xFF718096)))]),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _message('Pick list opened.'), icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('View'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _message('Picking task continued.'), icon: const Icon(Icons.play_arrow_rounded, size: 17), label: const Text('Continue')))]),
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
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F))),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _boxDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF172A43))), const SizedBox(height: 8), body]),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8F1)),
      boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))],
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
