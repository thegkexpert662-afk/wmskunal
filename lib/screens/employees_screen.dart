import 'package:flutter/material.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  String statusFilter = 'All';

  final List<Employee> employees = const [
    Employee(1, 'Rakesh Sharma', 'EMP-001', 'rakesh.sharma@wms.com', '9876543210', 'Main Warehouse', 'Warehouse Staff', true),
    Employee(2, 'Priya Verma', 'EMP-002', 'priya.verma@wms.com', '9876543211', 'Main Warehouse', 'Inventory Clerk', true),
    Employee(3, 'Amit Kumar', 'EMP-003', 'amit.kumar@wms.com', '9876543212', 'Delhi Warehouse', 'Warehouse Staff', true),
    Employee(4, 'Neha Singh', 'EMP-004', 'neha.singh@wms.com', '9876543213', 'Mumbai Warehouse', 'Inventory Clerk', true),
    Employee(5, 'Vikas Yadav', 'EMP-005', 'vikas.yadav@wms.com', '9876543214', 'Punjab Warehouse', 'Dispatch Handler', false),
    Employee(6, 'Sohan Patel', 'EMP-006', 'sohan.patel@wms.com', '9876543215', 'Main Warehouse', 'Warehouse Staff', true),
    Employee(7, 'Anjali Gupta', 'EMP-007', 'anjali.gupta@wms.com', '9876543216', 'Delhi Warehouse', 'Inventory Clerk', false),
    Employee(8, 'Rahul Mehta', 'EMP-008', 'rahul.mehta@wms.com', '9876543217', 'Mumbai Warehouse', 'Dispatch Handler', true),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Employee> get filteredEmployees {
    final query = searchText.trim().toLowerCase();
    return employees.where((employee) {
      final matchesSearch = query.isEmpty ||
          employee.name.toLowerCase().contains(query) ||
          employee.code.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.phone.contains(query) ||
          employee.warehouse.toLowerCase().contains(query) ||
          employee.role.toLowerCase().contains(query);
      final matchesStatus = statusFilter == 'All' ||
          (statusFilter == 'Active' && employee.active) ||
          (statusFilter == 'Inactive' && !employee.active);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get activeCount => employees.where((e) => e.active).length;
  int get inactiveCount => employees.where((e) => !e.active).length;

  void _showAddEmployee() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee'),
        content: const SizedBox(
          width: 420,
          child: Text(
            'Employee creation form will be connected to the WMS backend here.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FC),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (constraints.maxWidth > 700) _pageHeader(),
              const SizedBox(height: 22),
              _summaryCards(constraints),
              const SizedBox(height: 22),
              Expanded(child: _employeeTable(constraints)),
            ],
          );
        },
      ),
    );
  }

  Widget _pageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employees',
          style: TextStyle(
            color: Color(0xFF10243E),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Text(
              'Dashboard',
              style: TextStyle(color: Color(0xFF63758B), fontSize: 13),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 9),
              child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF9AA8B8)),
            ),
            Text(
              'Employees',
              style: TextStyle(color: Color(0xFF1769D5), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCards(BoxConstraints constraints) {
    final cards = [
      _SummaryCard(
        title: 'Total Employees',
        value: '${employees.length + 37}',
        subtitle: 'Active Employees',
        icon: Icons.groups_outlined,
        iconColor: const Color(0xFF1769D5),
        background: const Color(0xFFEAF3FF),
      ),
      _SummaryCard(
        title: 'Active Employees',
        value: '38',
        subtitle: '84.44% of Total',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF21A65B),
        background: const Color(0xFFE7F8EF),
      ),
      _SummaryCard(
        title: 'Inactive Employees',
        value: '7',
        subtitle: '15.56% of Total',
        icon: Icons.person_outline,
        iconColor: const Color(0xFFE93650),
        background: const Color(0xFFFFE8EC),
      ),
      _SummaryCard(
        title: 'New This Month',
        value: '5',
        subtitle: '11.11% of Total',
        icon: Icons.group_add_outlined,
        iconColor: const Color(0xFF6B3DD9),
        background: const Color(0xFFF0E9FF),
      ),
    ];

    final columns = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 700 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 14,
        mainAxisExtent: 128,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }

  Widget _employeeTable(BoxConstraints constraints) {
    final compact = constraints.maxWidth < 1100;
    final rows = filteredEmployees;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _showAddEmployee,
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Add Employee'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1769D5),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: compact ? 220 : 265,
                  height: 44,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => searchText = value),
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      prefixIcon: const Icon(Icons.search, size: 21),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9E0E8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9E0E8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showFilter,
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF27364A),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    side: const BorderSide(color: Color(0xFFD9E0E8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Export',
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD9E0E8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: compact ? 1200 : 0),
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 64,
                    columnSpacing: compact ? 25 : 34,
                    headingTextStyle: const TextStyle(
                      color: Color(0xFF43556B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xFF27364A),
                      fontSize: 12,
                    ),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Employee Code')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Warehouse')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: rows.map(_dataRow).toList(),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Text(
                  'Showing 1 to ${rows.length} of 45 entries',
                  style: const TextStyle(color: Color(0xFF718198), fontSize: 12),
                ),
                const Spacer(),
                _pageButton('Previous', enabled: false),
                _pageButton('1', selected: true),
                _pageButton('2'),
                _pageButton('3'),
                _pageButton('4'),
                _pageButton('5'),
                _pageButton('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _dataRow(Employee employee) {
    return DataRow(
      cells: [
        DataCell(Text('${employee.id}')),
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFEAF2FF),
              child: Text(
                employee.name.substring(0, 1),
                style: const TextStyle(color: Color(0xFF1769D5), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        )),
        DataCell(Text(employee.code)),
        DataCell(Text(employee.email)),
        DataCell(Text(employee.phone)),
        DataCell(Text(employee.warehouse)),
        DataCell(Text(employee.role)),
        DataCell(_statusChip(employee.active)),
        DataCell(Row(
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: const Color(0xFF1769D5),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, size: 18),
              color: const Color(0xFFE93650),
            ),
          ],
        )),
      ],
    );
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE4F7EA) : const Color(0xFFFFE8EC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? const Color(0xFF168044) : const Color(0xFFD62E47),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _pageButton(String label, {bool selected = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: enabled ? () {} : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            foregroundColor: selected ? Colors.white : const Color(0xFF5F7084),
            backgroundColor: selected ? const Color(0xFF1769D5) : Colors.white,
            side: BorderSide(color: selected ? const Color(0xFF1769D5) : const Color(0xFFE0E6ED)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showFilter() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Employees'),
        content: DropdownButtonFormField<String>(
          value: statusFilter,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => statusFilter = value);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Apply')),
        ],
      ),
    );
  }
}

class Employee {
  final int id;
  final String name;
  final String code;
  final String email;
  final String phone;
  final String warehouse;
  final String role;
  final bool active;

  const Employee(
    this.id,
    this.name,
    this.code,
    this.email,
    this.phone,
    this.warehouse,
    this.role,
    this.active,
  );
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF26374C))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF10243E))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF718198))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
