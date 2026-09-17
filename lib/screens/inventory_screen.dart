import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController searchController = TextEditingController();

  String categoryFilter = 'All';
  String warehouseFilter = 'All';
  String statusFilter = 'All';

  final List<List<String>> items = const [
    ['ITM-1001', 'Cotton Fabric Roll', 'Raw Material', 'Main Warehouse', 'Roll', '150', 'In Stock', '₹ 3,75,000'],
    ['ITM-1002', 'Polyester Fabric Roll', 'Raw Material', 'Main Warehouse', 'Roll', '80', 'Low Stock', '₹ 1,60,000'],
    ['ITM-1003', 'Thread 40s', 'Raw Material', 'Ankleshwar WH', 'Cone', '0', 'Out of Stock', '₹ 0'],
    ['ITM-1004', 'Packaging Box Large', 'Packaging', 'Vilayat Warehouse', 'Pcs', '200', 'In Stock', '₹ 40,000'],
    ['ITM-1005', 'Packing Tape 2 Inch', 'Packaging', 'Main Warehouse', 'Roll', '25', 'Low Stock', '₹ 3,750'],
    ['ITM-1006', 'Label 100x150', 'Stationery', 'Delhi Warehouse', 'Pcs', '0', 'Out of Stock', '₹ 0'],
    ['ITM-1007', 'Pallet Wooden', 'Material Handling', 'Main Warehouse', 'Pcs', '35', 'Low Stock', '₹ 14,000'],
    ['ITM-1008', 'Stretch Film', 'Packaging', 'Mumbai Warehouse', 'Roll', '120', 'In Stock', '₹ 12,900'],
  ];

  List<List<String>> get filteredItems {
    final query = searchController.text.trim().toLowerCase();

    return items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.any((value) => value.toLowerCase().contains(query));
      final matchesCategory =
          categoryFilter == 'All' || item[2] == categoryFilter;
      final matchesWarehouse =
          warehouseFilter == 'All' || item[3] == warehouseFilter;
      final matchesStatus = statusFilter == 'All' || item[6] == statusFilter;

      return matchesSearch &&
          matchesCategory &&
          matchesWarehouse &&
          matchesStatus;
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1050;

    return ScreenFrame(
      title: 'Inventory',
      subtitle: 'Stock by client, warehouse, SKU and batch.',
      actions: [
        OutlinedButton.icon(
          onPressed: _export,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryCards(compact),
          const SizedBox(height: 16),
          if (compact) ...[
            _stockOverview(),
            const SizedBox(height: 14),
            _stockValueChart(),
            const SizedBox(height: 14),
            _stockByCategory(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _stockOverview()),
                const SizedBox(width: 14),
                Expanded(flex: 5, child: _stockValueChart()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _stockByCategory()),
              ],
            ),
          const SizedBox(height: 16),
          if (compact) ...[
            _inventoryTable(),
            const SizedBox(height: 14),
            _alerts(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _inventoryTable()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _alerts()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryCards(bool compact) {
    final cards = [
      _statCard('Total Items', '1,250', 'All Items', Icons.inventory_2_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _statCard('In Stock', '875', '70.00% of Total', Icons.inventory_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _statCard('Low Stock', '120', '9.60% of Total', Icons.inventory_2_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)),
      _statCard('Out of Stock', '45', '3.60% of Total', Icons.inventory_2_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)),
      _statCard('Total Stock Value', '₹ 48,75,650', 'In Current Value', Icons.currency_rupee_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
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
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _statCard(
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
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _bold(12)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: _bold(23)),
                ),
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

  Widget _panel(
    String title,
    Widget body, {
    String? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: _bold(14)),
              const Spacer(),
              if (action != null)
                Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFF1769E8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }

  Widget _stockOverview() {
    return _panel(
      'Stock Overview',
      SizedBox(
        height: 190,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: CustomPaint(
                painter: _DonutPainter(),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('1,250', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF162B46))),
                      Text('Total Items', style: TextStyle(fontSize: 10, color: Color(0xFF77859A))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend('In Stock', '875 (70.00%)', const Color(0xFF1769E8)),
                  _legend('Low Stock', '120 (9.60%)', const Color(0xFFFFB20E)),
                  _legend('Out of Stock', '45 (3.60%)', const Color(0xFFE83C55)),
                  _legend('Total Items', '1,250 (100%)', const Color(0xFF22B86B)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF35465D)))),
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF24364D))),
        ],
      ),
    );
  }

  Widget _stockValueChart() {
    return _panel(
      'Stock Value (Last 7 Days)',
      SizedBox(
        height: 190,
        child: CustomPaint(
          painter: _LinePainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _stockByCategory() {
    return _panel(
      'Stock by Category',
      SizedBox(
        height: 190,
        child: Row(
          children: [
            SizedBox(
              width: 118,
              child: CustomPaint(
                painter: _CategoryPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend('Raw Material', '52% (650)', const Color(0xFF1769E8)),
                  _legend('Packaging', '20% (250)', const Color(0xFF22B86B)),
                  _legend('Material Handling', '15% (188)', const Color(0xFFFFB20E)),
                  _legend('Stationery', '8% (100)', const Color(0xFF7046D8)),
                  _legend('Others', '5% (62)', const Color(0xFF9AA6B6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryTable() {
    final rows = filteredItems;

    return _panel(
      'Inventory',
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
              columnSpacing: 22,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Item Code')),
                DataColumn(label: Text('Item Name')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('UOM')),
                DataColumn(label: Text('Stock Qty')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Stock Value')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(rows.length, (index) {
                final row = rows[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(row[0])),
                    DataCell(Text(row[1], style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(row[2])),
                    DataCell(Text(row[3])),
                    DataCell(Text(row[4])),
                    DataCell(Text(row[5])),
                    DataCell(_statusChip(row[6])),
                    DataCell(Text(row[7])),
                    DataCell(
                      IconButton(
                        onPressed: () => _message('Viewing ${row[1]}'),
                        tooltip: 'View',
                        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
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
                  'Showing 1 to ${rows.length} of 1,250 entries',
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
                ),
                const Spacer(),
                _pageButton('Prev'),
                _pageButton('1', active: true),
                _pageButton('2'),
                _pageButton('3'),
                _pageButton('4'),
                _pageButton('5'),
                _pageButton('…'),
                _pageButton('157'),
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
        spacing: 7,
        runSpacing: 7,
        children: [
          SizedBox(
            width: 310,
            height: 40,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name, SKU or barcode...',
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
          _dropdown(categoryFilter, ['All', 'Raw Material', 'Packaging', 'Material Handling', 'Stationery'], (value) => setState(() => categoryFilter = value!), 'Category'),
          _dropdown(warehouseFilter, ['All', 'Main Warehouse', 'Ankleshwar WH', 'Vilayat Warehouse', 'Delhi Warehouse', 'Mumbai Warehouse'], (value) => setState(() => warehouseFilter = value!), 'Warehouse'),
          _dropdown(statusFilter, ['All', 'In Stock', 'Low Stock', 'Out of Stock'], (value) => setState(() => statusFilter = value!), 'Status'),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
          ),
          OutlinedButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
    String label,
  ) {
    return Container(
      width: 145,
      height: 40,
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
          items: values
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item == 'All' ? '$label: All' : item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final bool low = status == 'Low Stock';
    final bool out = status == 'Out of Stock';
    final Color foreground = out
        ? const Color(0xFFD92F4B)
        : low
            ? const Color(0xFFE28C00)
            : const Color(0xFF14894E);
    final Color background = out
        ? const Color(0xFFFFE5EA)
        : low
            ? const Color(0xFFFFF0D8)
            : const Color(0xFFE4F7EC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _pageButton(String label, {bool active = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      height: 30,
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1769E8) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF),
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

  Widget _alerts() {
    return Column(
      children: [
        _alertCard(
          'Low Stock Alerts',
          const Color(0xFFEBA311),
          Icons.warning_amber_rounded,
          const [
            ['Polyester Fabric Roll', 'Qty: 80', 'Ankleshwar WH'],
            ['Packing Tape 2 Inch', 'Qty: 25', 'Main Warehouse'],
            ['Pallet Wooden', 'Qty: 35', 'Main Warehouse'],
          ],
        ),
        const SizedBox(height: 12),
        _alertCard(
          'Out of Stock Alerts',
          const Color(0xFFE83C55),
          Icons.inventory_2_outlined,
          const [
            ['Thread 40s', 'Last In: 10 May 2025', 'Ankleshwar WH'],
            ['Label 100x150', 'Last In: 12 May 2025', 'Delhi Warehouse'],
          ],
        ),
      ],
    );
  }

  Widget _alertCard(
    String title,
    Color color,
    IconData icon,
    List<List<String>> data,
  ) {
    return _panel(
      title,
      Column(
        children: [
          for (int i = 0; i < data.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data[i][0], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                        Text(data[i][2], style: const TextStyle(fontSize: 8, color: Color(0xFF8793A4))),
                      ],
                    ),
                  ),
                  Text(data[i][1], style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (i < data.length - 1) const Divider(height: 1),
          ],
        ],
      ),
      action: 'View All',
    );
  }

  void _export() {
    _message('Inventory exported successfully.');
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.30;

    const values = [70.0, 9.6, 3.6, 16.8];
    const colors = [
      Color(0xFF1769E8),
      Color(0xFFFFB20E),
      Color(0xFFE83C55),
      Color(0xFF22B86B),
    ];

    var start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / 100;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + 0.025;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.32;

    const values = [52.0, 20.0, 15.0, 8.0, 5.0];
    const colors = [
      Color(0xFF1769E8),
      Color(0xFF22B86B),
      Color(0xFFFFB20E),
      Color(0xFF7046D8),
      Color(0xFF9AA6B6),
    ];

    var start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / 100;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + 0.018;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 7.0;
    const top = 14.0;
    const bottom = 30.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    const values = [28.0, 35.0, 40.0, 36.0, 42.0, 38.0, 51.0];
    const labels = [
      '19 May',
      '20 May',
      '21 May',
      '22 May',
      '23 May',
      '24 May',
      '25 May',
    ];

    final linePaint = Paint()
      ..color = const Color(0xFF1769E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = left + chartWidth * i / (values.length - 1);
      final y = top + chartHeight * (60 - values[i]) / 60;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()..color = const Color(0xFF1769E8),
      );
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < labels.length; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 7, color: Color(0xFF7B8798)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = left + chartWidth * i / (labels.length - 1);
      text.paint(canvas, Offset(x - text.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
