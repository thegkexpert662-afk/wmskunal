import 'package:flutter/material.dart';
import 'common_widgets.dart';

class MasterUsersRolesScreen extends StatefulWidget {
  const MasterUsersRolesScreen({super.key});

  @override
  State<MasterUsersRolesScreen> createState() => _MasterUsersRolesScreenState();
}

class _MasterUsersRolesScreenState extends State<MasterUsersRolesScreen> {
  final TextEditingController search = TextEditingController();
  String role = 'All';
  String status = 'All';

  final List<List<String>> users = const [
    ['USR-001', 'Admin User', 'admin@kopersay.com', 'Company Admin', 'All Brands', 'Today', 'Active'],
    ['USR-002', 'Manager A', 'manager.a@kopersay.com', 'Brand Manager', 'Brand A', 'Today', 'Active'],
    ['USR-003', 'Manager B', 'manager.b@kopersay.com', 'Brand Manager', 'Brand B', 'Today', 'Active'],
    ['USR-004', 'Client A1', 'admin@abc.com', 'Client User', 'ABC Industries', 'Today', 'Active'],
    ['USR-005', 'Warehouse User', 'warehouse@kopersay.com', 'Warehouse User', 'WH-A', 'Yesterday', 'Active'],
    ['USR-006', 'Accounts User', 'accounts@kopersay.com', 'Accounts', 'Company Billing', '15 Sep', 'Inactive'],
  ];

  List<List<String>> get filteredUsers {
    final q = search.text.toLowerCase().trim();
    return users.where((u) {
      final matchesSearch = q.isEmpty || u.any((v) => v.toLowerCase().contains(q));
      final matchesRole = role == 'All' || u[3] == role;
      final matchesStatus = status == 'All' || u[6] == status;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
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
      title: 'Users & Roles',
      subtitle: 'Manage users, roles, permissions and access scope.',
      actions: [
        FilledButton.icon(
          onPressed: () => _message('Add User form opened.'),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add User'),
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
                _userTable(),
                const SizedBox(height: 14),
                _roleDetails(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _userTable()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _roleDetails()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stats(bool compact) {
    final data = [
      ['Total Users', '06', 'All Registered', Icons.groups_2_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)],
      ['Active Users', '05', 'Currently Active', Icons.verified_user_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['Company Admins', '01', 'Full Company Scope', Icons.admin_panel_settings_outlined, const Color(0xFF7447D8), const Color(0xFFF0EAFF)],
      ['Brand Managers', '02', 'Brand Scoped', Icons.manage_accounts_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)],
      ['Client Users', '01', 'Client Scoped', Icons.business_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)],
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
                FittedBox(
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

  Widget _userTable() {
    return _panel(
      'User List',
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
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Access Scope')),
                DataColumn(label: Text('Last Login')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(filteredUsers.length, (index) {
                final u = filteredUsers[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(u[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(u[1], style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(u[2])),
                    DataCell(_roleChip(u[3])),
                    DataCell(Text(u[4])),
                    DataCell(Text(u[5])),
                    DataCell(_statusChip(u[6])),
                    DataCell(_viewButton(u[0])),
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
                  'Showing 1 to ${filteredUsers.length} of 6 entries',
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
                ),
                const Spacer(),
                _pageButton('Prev'),
                _pageButton('1', true),
                _pageButton('2'),
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
            width: 320,
            height: 40,
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: 'Search user, email or role...',
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
          _dropdown(
            role,
            const ['All', 'Company Admin', 'Brand Manager', 'Client User', 'Warehouse User', 'Accounts'],
            (value) => setState(() => role = value ?? 'All'),
            'Role',
          ),
          _dropdown(
            status,
            const ['All', 'Active', 'Inactive'],
            (value) => setState(() => status = value ?? 'All'),
            'Status',
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
            onPressed: () => _message('User list exported successfully.'),
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

  Widget _dropdown(
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
    String label,
  ) {
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
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF42546A),
            fontWeight: FontWeight.w600,
          ),
          items: values.map((item) {
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

  Widget _roleChip(String value) {
    Color color;
    Color background;

    if (value == 'Company Admin') {
      color = const Color(0xFF7447D8);
      background = const Color(0xFFF0EAFF);
    } else if (value == 'Brand Manager') {
      color = const Color(0xFF1769E8);
      background = const Color(0xFFEAF2FF);
    } else if (value == 'Client User') {
      color = const Color(0xFFE83C55);
      background = const Color(0xFFFFE9ED);
    } else {
      color = const Color(0xFF63738A);
      background = const Color(0xFFF0F3F7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statusChip(String value) {
    final active = value == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE4F7EC) : const Color(0xFFFFE5EA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: active ? const Color(0xFF14894E) : const Color(0xFFD92F4B),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _viewButton(String id) {
    return IconButton(
      onPressed: () => _message('Viewing user $id'),
      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
      tooltip: 'View user',
    );
  }

  Widget _roleDetails() {
    return _panel(
      'Roles & Access',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _accessCard('Company Admin', 'Full company access', Icons.admin_panel_settings_outlined, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
          _accessCard('Brand Manager', 'Brand and assigned warehouse access', Icons.manage_accounts_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
          _accessCard('Client User', 'Own client data and invoices only', Icons.business_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)),
          _accessCard('Warehouse User', 'Warehouse operations only', Icons.warehouse_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
          const Divider(height: 22),
          const Text('Permission controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
          const SizedBox(height: 8),
          _permission('View Inventory', true),
          _permission('Create Inward / GRN', true),
          _permission('Create Dispatch', true),
          _permission('Generate Invoice', false),
          _permission('Manage Users', false),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _message('Role and permission settings opened.'),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Manage Roles & Permissions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessCard(String title, String subtitle, IconData icon, Color color, Color background) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF718096))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permission(String title, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: enabled ? const Color(0xFF16A05D) : const Color(0xFF9AA6B5),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF42546A)))),
          Text(enabled ? 'Allowed' : 'Restricted', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: enabled ? const Color(0xFF16A05D) : const Color(0xFF9AA6B5))),
        ],
      ),
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

  Widget _pageButton(String text, [bool active = false]) {
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

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
