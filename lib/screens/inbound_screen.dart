import 'package:flutter/material.dart';

class InboundScreen extends StatefulWidget {
  const InboundScreen({super.key});

  @override
  State<InboundScreen> createState() => _InboundScreenState();
}

class _InboundScreenState extends State<InboundScreen> {
  final TextEditingController searchController = TextEditingController();
  String statusFilter = 'All';
  String warehouseFilter = 'All';
  int selectedIndex = 0;

  final List<Map<String, dynamic>> grns = [
    {
      'grn': 'GRN-2025-00125',
      'date': '25-05-2025',
      'supplier': 'ABC Textiles Pvt. Ltd.',
      'invoice': 'INV-2587',
      'warehouse': 'Main Warehouse',
      'items': 8,
      'qty': 120,
      'value': '₹ 2,45,600',
      'status': 'Received',
    },
    {
      'grn': 'GRN-2025-00124',
      'date': '24-05-2025',
      'supplier': 'Shree Ram Suppliers',
      'invoice': 'INV-2586',
      'warehouse': 'Ankleshwar WH',
      'items': 5,
      'qty': 85,
      'value': '₹ 1,20,500',
      'status': 'Received',
    },
    {
      'grn': 'GRN-2025-00123',
      'date': '23-05-2025',
      'supplier': 'Reliable Packaging',
      'invoice': 'INV-2585',
      'warehouse': 'Vilayat Warehouse',
      'items': 6,
      'qty': 200,
      'value': '₹ 3,10,000',
      'status': 'Received',
    },
    {
      'grn': 'GRN-2025-00122',
      'date': '22-05-2025',
      'supplier': 'Om Plastics',
      'invoice': 'INV-2584',
      'warehouse': 'Main Warehouse',
      'items': 4,
      'qty': 150,
      'value': '₹ 1,50,000',
      'status': 'Pending',
    },
    {
      'grn': 'GRN-2025-00121',
      'date': '21-05-2025',
      'supplier': 'ABC Textiles Pvt. Ltd.',
      'invoice': 'INV-2583',
      'warehouse': 'Delhi Warehouse',
      'items': 7,
      'qty': 95,
      'value': '₹ 1,75,250',
      'status': 'Verified',
    },
    {
      'grn': 'GRN-2025-00120',
      'date': '20-05-2025',
      'supplier': 'Shree Ram Suppliers',
      'invoice': 'INV-2582',
      'warehouse': 'Main Warehouse',
      'items': 6,
      'qty': 180,
      'value': '₹ 2,80,000',
      'status': 'Received',
    },
    {
      'grn': 'GRN-2025-00119',
      'date': '19-05-2025',
      'supplier': 'Reliable Packaging',
      'invoice': 'INV-2581',
      'warehouse': 'Ankleshwar WH',
      'items': 5,
      'qty': 160,
      'value': '₹ 2,20,000',
      'status': 'Cancelled',
    },
    {
      'grn': 'GRN-2025-00118',
      'date': '18-05-2025',
      'supplier': 'Om Plastics',
      'invoice': 'INV-2580',
      'warehouse': 'Vilayat Warehouse',
      'items': 3,
      'qty': 75,
      'value': '₹ 85,600',
      'status': 'Pending',
    },
    {
      'grn': 'GRN-2025-00117',
      'date': '17-05-2025',
      'supplier': 'JK Traders',
      'invoice': 'INV-2579',
      'warehouse': 'Main Warehouse',
      'items': 9,
      'qty': 210,
      'value': '₹ 4,10,000',
      'status': 'Received',
    },
    {
      'grn': 'GRN-2025-00116',
      'date': '16-05-2025',
      'supplier': 'National Fabrics',
      'invoice': 'INV-2578',
      'warehouse': 'Delhi Warehouse',
      'items': 4,
      'qty': 110,
      'value': '₹ 1,45,300',
      'status': 'Verified',
    },
  ];

  List<Map<String, dynamic>> get filteredGrns {
    final query = searchController.text.trim().toLowerCase();

    return grns.where((grn) {
      final matchesSearch = query.isEmpty ||
          grn.values.any((value) => value.toString().toLowerCase().contains(query));
      final matchesStatus =
          statusFilter == 'All' || grn['status'] == statusFilter;
      final matchesWarehouse =
          warehouseFilter == 'All' || grn['warehouse'] == warehouseFilter;
      return matchesSearch && matchesStatus && matchesWarehouse;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;
    final rows = filteredGrns;

    return Container(
      color: const Color(0xFFF7F9FC),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 22, compact ? 16 : 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(compact),
            const SizedBox(height: 20),
            _summaryCards(compact),
            const SizedBox(height: 20),
            if (compact)
              _compactContent(rows)
            else
              _desktopContent(rows),
          ],
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inbound / GRN',
                style: TextStyle(
                  color: Color(0xFF122640),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Receive material, create GRN and manage incoming stock.',
                style: TextStyle(color: Color(0xFF718096), fontSize: 13),
              ),
            ],
          ),
        ),
        if (!compact)
          FilledButton.icon(
            onPressed: _createGrn,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create GRN'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1463E8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
      ],
    );
  }

  Widget _summaryCards(bool compact) {
    final cards = [
      _summaryCard(
        'Total GRNs',
        '125',
        'All Time',
        Icons.description_outlined,
        const Color(0xFF1769D5),
        const Color(0xFFEAF3FF),
      ),
      _summaryCard(
        'This Month',
        '18',
        'May 2025',
        Icons.check_circle_outline_rounded,
        const Color(0xFF17A15B),
        const Color(0xFFE8FAF0),
      ),
      _summaryCard(
        'Total Received Qty',
        '2,850',
        'All Items',
        Icons.inventory_2_outlined,
        const Color(0xFFE69A12),
        const Color(0xFFFFF5E4),
      ),
      _summaryCard(
        'Total Value',
        '₹ 48,75,650',
        'All Time',
        Icons.currency_rupee_rounded,
        const Color(0xFF7448D8),
        const Color(0xFFF0E9FF),
      ),
    ];

    if (compact) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
        children: cards,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B18304F),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2D45))),
                const SizedBox(height: 5),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF132A49))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF748297))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopContent(List<Map<String, dynamic>> rows) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _tablePanel(rows)),
        const SizedBox(width: 16),
        SizedBox(width: 310, child: _detailsPanel()),
      ],
    );
  }

  Widget _compactContent(List<Map<String, dynamic>> rows) {
    return Column(
      children: [
        _tablePanel(rows),
        const SizedBox(height: 16),
        _detailsPanel(),
      ],
    );
  }

  Widget _tablePanel(List<Map<String, dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E9F1)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A18304F), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _filterBar(),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 55,
              dataRowMaxHeight: 58,
              columnSpacing: 25,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('GRN No.')),
                DataColumn(label: Text('GRN Date')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Invoice No.')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Total Qty')),
                DataColumn(label: Text('Total Value')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(rows.length, (index) {
                final grn = rows[index];
                final selected = selectedIndex == grns.indexOf(grn);
                return DataRow(
                  selected: selected,
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFF5F9FF);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(grn['grn'], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(grn['date'])),
                    DataCell(Text(grn['supplier'])),
                    DataCell(Text(grn['invoice'])),
                    DataCell(Text(grn['warehouse'])),
                    DataCell(Text('${grn['items']}')),
                    DataCell(Text('${grn['qty']}')),
                    DataCell(Text(grn['value'])),
                    DataCell(_statusChip(grn['status'])),
                    DataCell(
                      _viewButton(() {
                        setState(() => selectedIndex = grns.indexOf(grn));
                      }),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          _footer(rows.length),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 300, child: _searchField()),
          _smallDropdown('Warehouse', warehouseFilter, [
            'All', 'Main Warehouse', 'Ankleshwar WH', 'Vilayat Warehouse', 'Delhi Warehouse'
          ], (value) => setState(() => warehouseFilter = value!)),
          _smallDropdown('Status', statusFilter, [
            'All', 'Received', 'Verified', 'Pending', 'Cancelled'
          ], (value) => setState(() => statusFilter = value!)),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.filter_alt_outlined, size: 17),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF293C54),
              side: const BorderSide(color: Color(0xFFDDE5EF)),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
          FilledButton.icon(
            onPressed: _createGrn,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create GRN'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1463E8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by GRN No., Supplier, Invoice...',
        hintStyle: const TextStyle(color: Color(0xFF8A96A7), fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF718096), size: 19),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
        ),
      ),
    );
  }

  Widget _smallDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(color: Color(0xFF45566B), fontSize: 12, fontWeight: FontWeight.w600),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text('$label: $item'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color background;
    Color foreground;

    switch (status) {
      case 'Received':
        background = const Color(0xFFE2F8EB);
        foreground = const Color(0xFF16894D);
        break;
      case 'Verified':
        background = const Color(0xFFE8F2FF);
        foreground = const Color(0xFF2269C7);
        break;
      case 'Pending':
        background = const Color(0xFFFFF2D9);
        foreground = const Color(0xFFD98A08);
        break;
      default:
        background = const Color(0xFFFFE7EB);
        foreground = const Color(0xFFD72F4B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: foreground, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _viewButton(VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E7F0)),
        ),
        child: const Icon(Icons.visibility_outlined, color: Color(0xFF1769D5), size: 18),
      ),
    );
  }

  Widget _footer(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Text('Showing 1 to $count of 125 entries', style: const TextStyle(color: Color(0xFF718096), fontSize: 11.5)),
          const Spacer(),
          _pageButton(Icons.chevron_left_rounded, false),
          const SizedBox(width: 6),
          _pageButton(null, true, label: '1'),
          const SizedBox(width: 6),
          _pageButton(null, false, label: '2'),
          const SizedBox(width: 6),
          _pageButton(null, false, label: '3'),
          const SizedBox(width: 6),
          _pageButton(null, false, label: '4'),
          const SizedBox(width: 6),
          _pageButton(Icons.chevron_right_rounded, false),
        ],
      ),
    );
  }

  Widget _pageButton(IconData? icon, bool active, {String? label}) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1463E8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? const Color(0xFF1463E8) : const Color(0xFFE0E7F0)),
      ),
      child: icon != null
          ? Icon(icon, size: 18, color: const Color(0xFF65758A))
          : Text(label!, style: TextStyle(color: active ? Colors.white : const Color(0xFF65758A), fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _detailsPanel() {
    final grn = grns[selectedIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E9F1)),
        boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(child: Text('GRN Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF172A43)))),
                IconButton(onPressed: () {}, icon: const Icon(Icons.close_rounded, size: 19)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusChip(grn['status']),
                const SizedBox(height: 10),
                Text(grn['grn'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF162A47))),
                const SizedBox(height: 4),
                Text('${grn['date']} | 10:30 AM', style: const TextStyle(color: Color(0xFF748297), fontSize: 11)),
                const SizedBox(height: 18),
                _detailRow(Icons.person_outline, 'Supplier', grn['supplier']),
                _detailRow(Icons.receipt_long_outlined, 'Invoice No.', grn['invoice']),
                _detailRow(Icons.calendar_today_outlined, 'Invoice Date', '24-05-2025'),
                _detailRow(Icons.warehouse_outlined, 'Warehouse', grn['warehouse']),
                _detailRow(Icons.person_outline, 'Received By', 'Rakesh Sharma'),
                _detailRow(Icons.inventory_2_outlined, 'Total Items', '${grn['items']}'),
                _detailRow(Icons.scale_outlined, 'Total Quantity', '${grn['qty']}'),
                _detailRow(Icons.currency_rupee_rounded, 'Total Value', grn['value']),
                _detailRow(Icons.notes_outlined, 'Remarks', 'All items received in good condition.'),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Items Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF172A43))),
          ),
          _itemSummary(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Download GRN'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print GRN'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF63758C)),
          const SizedBox(width: 9),
          SizedBox(width: 78, child: Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF617187), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10.5, color: Color(0xFF23354B), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _itemSummary() {
    const items = [
      ['Cotton Fabric Roll', 'COT-001', '20', 'Roll'],
      ['Polyester Fabric Roll', 'POL-002', '15', 'Roll'],
      ['Thread 40s', 'THR-040', '30', 'Cone'],
      ['Packaging Box Large', 'PCK-001', '25', 'Pcs'],
      ['Plastic Cover', 'PLC-001', '10', 'Pcs'],
      ['Label 100x150', 'LB-100', '10', 'Pcs'],
      ['Stretch Film', 'STR-001', '5', 'Roll'],
      ['Tape 2 Inch', 'TAP-002', '5', 'Roll'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const Row(
            children: [
              SizedBox(width: 18, child: Text('#', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
              Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
              Expanded(child: Text('SKU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
              Expanded(child: Text('Qty', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
              Expanded(child: Text('UOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
            ],
          ),
          const Divider(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(width: 18, child: Text('${index + 1}', style: const TextStyle(fontSize: 8.5))),
                  Expanded(flex: 3, child: Text(item[0], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5))),
                  Expanded(child: Text(item[1], style: const TextStyle(fontSize: 8.5))),
                  Expanded(child: Text(item[2], style: const TextStyle(fontSize: 8.5))),
                  Expanded(child: Text(item[3], style: const TextStyle(fontSize: 8.5))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _createGrn() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create GRN form will open here.')));
  }
}
