import 'package:flutter/material.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final TextEditingController searchController = TextEditingController();
  String statusFilter = 'All';
  String locationFilter = 'All';

  final List<Map<String, String>> warehouses = [
    {
      'code': 'WH-001',
      'name': 'Main Warehouse',
      'location': 'Mumbai, Maharashtra',
      'status': 'Active',
      'manager': 'Rakesh Sharma',
      'created': '01-01-2025',
    },
    {
      'code': 'WH-002',
      'name': 'Ankleshwar Warehouse',
      'location': 'Ankleshwar, Gujarat',
      'status': 'Active',
      'manager': 'Mohit Patel',
      'created': '15-01-2025',
    },
    {
      'code': 'WH-003',
      'name': 'Vilayat Warehouse',
      'location': 'Vilayat, Gujarat',
      'status': 'Active',
      'manager': 'Suresh Kumar',
      'created': '20-01-2025',
    },
    {
      'code': 'WH-004',
      'name': 'Delhi Warehouse',
      'location': 'Delhi',
      'status': 'Inactive',
      'manager': 'Amit Verma',
      'created': '25-01-2025',
    },
    {
      'code': 'WH-005',
      'name': 'Kolkata Warehouse',
      'location': 'Kolkata, West Bengal',
      'status': 'Active',
      'manager': 'Pranab Dey',
      'created': '02-02-2025',
    },
    {
      'code': 'WH-006',
      'name': 'Chennai Warehouse',
      'location': 'Chennai, Tamil Nadu',
      'status': 'Active',
      'manager': 'Vignesh M',
      'created': '10-02-2025',
    },
    {
      'code': 'WH-007',
      'name': 'Bangalore Warehouse',
      'location': 'Bangalore, Karnataka',
      'status': 'Active',
      'manager': 'Mahesh R',
      'created': '18-02-2025',
    },
    {
      'code': 'WH-008',
      'name': 'Pune Warehouse',
      'location': 'Pune, Maharashtra',
      'status': 'Active',
      'manager': 'Dinesh Jadhav',
      'created': '24-02-2025',
    },
  ];

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

  List<Map<String, String>> get filteredWarehouses {
    final query = searchController.text.trim().toLowerCase();
    return warehouses.where((warehouse) {
      final searchMatch = query.isEmpty ||
          warehouse.values.any((value) => value.toLowerCase().contains(query));
      final statusMatch = statusFilter == 'All' ||
          warehouse['status'] == statusFilter;
      final locationMatch = locationFilter == 'All' ||
          warehouse['location']!.startsWith(locationFilter);
      return searchMatch && statusMatch && locationMatch;
    }).toList();
  }

  int get activeCount =>
      warehouses.where((warehouse) => warehouse['status'] == 'Active').length;

  int get inactiveCount => warehouses.length - activeCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(compact),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 30,
                  26,
                  compact ? 16 : 30,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(compact),
                    const SizedBox(height: 22),
                    _stats(compact),
                    const SizedBox(height: 22),
                    _tableCard(compact),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool compact) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E8F1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded),
            color: const Color(0xFF1D334F),
          ),
          const SizedBox(width: 12),
          const Text(
            'Warehouse',
            style: TextStyle(
              color: Color(0xFF152A45),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (!compact) ...[
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDE5EF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 17, color: Color(0xFF63738A)),
                  SizedBox(width: 9),
                  Text('May 19 – May 25, 2025',
                      style: TextStyle(
                          color: Color(0xFF43536A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 12),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                color: const Color(0xFF506178),
              ),
              Positioned(
                right: 3,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8345A),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('5',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFE8EEF8),
            child: Icon(Icons.person, color: Color(0xFF65758B)),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin User',
                    style: TextStyle(
                        color: Color(0xFF17283F),
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Administrator',
                    style: TextStyle(color: Color(0xFF7A899C), fontSize: 11)),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ],
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
              Text('Warehouse List',
                  style: TextStyle(
                      color: Color(0xFF142943),
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Manage all warehouses in your organization',
                  style: TextStyle(color: Color(0xFF69798E), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: () => _showMessage('Add Warehouse'),
          icon: const Icon(Icons.add_rounded, size: 21),
          label: const Text('Add Warehouse'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1768E8),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stats(bool compact) {
    final cards = [
      _statCard(Icons.warehouse_outlined, 'Total Warehouses',
          '${warehouses.length}', 'All Warehouses', const Color(0xFF1769D5),
          const Color(0xFFEAF3FF)),
      _statCard(Icons.check_circle_outline_rounded, 'Active Warehouses',
          '$activeCount', 'Currently Active', const Color(0xFF13A05A),
          const Color(0xFFE7FAF0)),
      _statCard(Icons.cancel_outlined, 'Inactive Warehouses', '$inactiveCount',
          'Currently Inactive', const Color(0xFFE99A12),
          const Color(0xFFFFF5E3)),
      _statCard(Icons.location_on_outlined, 'Total Locations',
          '${warehouses.length}', 'Across All Warehouses', const Color(0xFF7448D8),
          const Color(0xFFF0EAFF)),
    ];

    if (compact) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.25,
        children: cards,
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _statCard(IconData icon, String title, String value, String subtitle,
      Color iconColor, Color iconBackground) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C18304F),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF1B2C42),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF132947),
                        fontSize: 27,
                        fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF718096), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCard(bool compact) {
    final rows = filteredWarehouses;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C18304F),
            blurRadius: 17,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _filterBar(compact),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          if (compact)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8EDF4)),
              itemBuilder: (_, index) => _mobileRow(rows[index], index),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _dataTable(rows),
            ),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          _footer(rows.length),
        ],
      ),
    );
  }

  Widget _filterBar(bool compact) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: compact
          ? Column(
              children: [
                _searchField(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _statusDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _locationDropdown()),
                    const SizedBox(width: 8),
                    _filterButton(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 380, child: _searchField()),
                const Spacer(),
                SizedBox(width: 145, child: _statusDropdown()),
                const SizedBox(width: 12),
                SizedBox(width: 155, child: _locationDropdown()),
                const SizedBox(width: 12),
                _filterButton(),
              ],
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search warehouse by code, name or location...',
        hintStyle: const TextStyle(color: Color(0xFF8491A3), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF718096)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF1769D5), width: 1.5),
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return _dropdown(
      statusFilter,
      const ['All', 'Active', 'Inactive'],
      (value) => setState(() => statusFilter = value!),
    );
  }

  Widget _locationDropdown() {
    return _dropdown(
      locationFilter,
      const [
        'All',
        'Mumbai',
        'Ankleshwar',
        'Vilayat',
        'Delhi',
        'Kolkata',
        'Chennai',
        'Bangalore',
        'Pune',
      ],
      (value) => setState(() => locationFilter = value!),
    );
  }

  Widget _dropdown(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDDE5EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
          style: const TextStyle(
              color: Color(0xFF4A5B70),
              fontSize: 13,
              fontWeight: FontWeight.w600),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _filterButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() {}),
      icon: const Icon(Icons.filter_alt_outlined, size: 18),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF273A52),
        side: const BorderSide(color: Color(0xFFDDE5EF)),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _dataTable(List<Map<String, String>> rows) {
    return DataTable(
      headingRowHeight: 50,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 60,
      columnSpacing: 34,
      headingRowColor:
          const MaterialStatePropertyAll<Color>(Color(0xFFFAFBFD)),
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Warehouse Code')),
        DataColumn(label: Text('Warehouse Name')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Manager')),
        DataColumn(label: Text('Created On')),
        DataColumn(label: Text('Actions')),
      ],
      rows: List.generate(rows.length, (index) {
        final warehouse = rows[index];
        return DataRow(
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text(warehouse['code']!)),
            DataCell(Text(warehouse['name']!,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(warehouse['location']!)),
            DataCell(_statusChip(warehouse['status']!)),
            DataCell(Text(warehouse['manager']!)),
            DataCell(Text(warehouse['created']!)),
            DataCell(_actions(warehouse)),
          ],
        );
      }),
    );
  }

  Widget _mobileRow(Map<String, String> warehouse, int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(warehouse['name']!,
                    style: const TextStyle(
                        color: Color(0xFF172A43),
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              _statusChip(warehouse['status']!),
            ],
          ),
          const SizedBox(height: 9),
          Text('${warehouse['code']} • ${warehouse['location']}'),
          const SizedBox(height: 5),
          Text('Manager: ${warehouse['manager']}'),
          const SizedBox(height: 5),
          Text('Created: ${warehouse['created']}'),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: _actions(warehouse)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE5F8EC) : const Color(0xFFFFE9EC),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(status,
          style: TextStyle(
              color: active ? const Color(0xFF138A4D) : const Color(0xFFD62E4A),
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _actions(Map<String, String> warehouse) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(Icons.edit_outlined, const Color(0xFF1769D5),
            () => _showMessage('Edit ${warehouse['name']}')),
        const SizedBox(width: 8),
        _actionButton(Icons.delete_outline_rounded, const Color(0xFFE63C55),
            () => _confirmDelete(warehouse)),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E8F1)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _footer(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text('Showing 1 to $count of ${warehouses.length} entries',
              style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
          const Spacer(),
          _pageButton(Icons.arrow_back_rounded, false),
          const SizedBox(width: 7),
          _pageButton(null, true, label: '1'),
          const SizedBox(width: 7),
          _pageButton(Icons.arrow_forward_rounded, false),
        ],
      ),
    );
  }

  Widget _pageButton(IconData? icon, bool active, {String? label}) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1463E8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active ? const Color(0xFF1463E8) : const Color(0xFFE0E7F0)),
      ),
      child: icon != null
          ? Icon(icon, size: 17, color: const Color(0xFF64748B))
          : Text(label!,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDelete(Map<String, String> warehouse) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Warehouse?'),
        content: Text('Delete ${warehouse['name']} from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => warehouses.remove(warehouse));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
