import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final TextEditingController search = TextEditingController();
  String status = 'All';

  final List<List<String>> clients = const [
    ['CL-001', 'ABC Industries', 'Brand A', 'WH-A', 'Rajesh Mehta', 'admin@abc.com', '128', 'Active', '₹ 12,84,500'],
    ['CL-002', 'Metro Retail', 'Brand A', 'WH-B', 'Neha Singh', 'ops@metro.com', '96', 'Active', '₹ 8,42,800'],
    ['CL-003', 'Prime Traders', 'Brand B', 'WH-A', 'Amit Patel', 'store@prime.com', '74', 'Active', '₹ 5,76,400'],
    ['CL-004', 'Global Parts', 'Brand B', 'WH-C', 'Vikas Sharma', 'logistics@global.com', '52', 'Pending', '₹ 2,34,250'],
    ['CL-005', 'Shree Logistics', 'Brand C', 'WH-B', 'Suresh Kumar', 'shree@example.com', '41', 'Inactive', '₹ 1,82,600'],
    ['CL-006', 'National Distributors', 'Brand A', 'WH-A', 'Pooja Verma', 'national@example.com', '68', 'Active', '₹ 7,45,900'],
  ];

  List<List<String>> get filtered {
    final String query = search.text.toLowerCase().trim();
    return clients.where((List<String> row) {
      final bool matchesSearch = query.isEmpty ||
          row.any((String value) => value.toLowerCase().contains(query));
      final bool matchesStatus = status == 'All' || row[7] == status;
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
    final bool compact = MediaQuery.sizeOf(context).width < 1050;

    return ScreenFrame(
      title: 'Clients',
      subtitle: 'Client master, brand assignment and warehouse access.',
      actions: [
        FilledButton.icon(
          onPressed: () => _msg('Add Client form opened.'),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Add Client'),
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
    final List<Widget> cards = [
      _stat('Total Clients', '40', 'All Registered', Icons.groups_2_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _stat('Active Clients', '34', '85% Active', Icons.verified_user_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _stat('Pending', '04', 'Awaiting Approval', Icons.pending_actions_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)),
      _stat('Inactive', '02', 'Currently Disabled', Icons.person_off_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)),
      _stat('Total Billing', '₹ 48,75,650', 'Current Period', Icons.currency_rupee_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
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
    final List<List<String>> rows = filtered;

    return _panel(
      'Client List',
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
              headingRowColor: const MaterialStatePropertyAll<Color>(Color(0xFFFAFBFD)),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Client ID')),
                DataColumn(label: Text('Client Name')),
                DataColumn(label: Text('Brand')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Contact Person')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Orders')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Billing')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(rows.length, (int index) {
                final List<String> row = rows[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(row[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(row[1], style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(row[2])),
                    DataCell(Text(row[3])),
                    DataCell(Text(row[4])),
                    DataCell(Text(row[5])),
                    DataCell(Text(row[6])),
                    DataCell(_chip(row[7])),
                    DataCell(Text(row[8])),
                    DataCell(_view(row[0])),
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
                  'Showing 1 to ${rows.length} of 40 entries',
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
                ),
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
                hintText: 'Search client, contact, email...',
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
          _statusDropdown(),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _msg('Client list exported successfully.'),
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

  Widget _statusDropdown() {
    return SizedBox(
      width: 130,
      height: 40,
      child: DropdownButtonFormField<String>(
        value: status,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
          ),
        ),
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF42546A),
          fontWeight: FontWeight.w600,
        ),
        items: const [
          DropdownMenuItem<String>(value: 'All', child: Text('Status: All')),
          DropdownMenuItem<String>(value: 'Active', child: Text('Active')),
          DropdownMenuItem<String>(value: 'Pending', child: Text('Pending')),
          DropdownMenuItem<String>(value: 'Inactive', child: Text('Inactive')),
        ],
        onChanged: (String? value) {
          if (value == null) return;
          setState(() => status = value);
        },
      ),
    );
  }

  Widget _chip(String value) {
    final bool active = value == 'Active';
    final bool pending = value == 'Pending';
    final Color textColor = active
        ? const Color(0xFF14894E)
        : pending
            ? const Color(0xFFE28C00)
            : const Color(0xFFD92F4B);
    final Color background = active
        ? const Color(0xFFE4F7EC)
        : pending
            ? const Color(0xFFFFF0D8)
            : const Color(0xFFFFE5EA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _view(String id) {
    return IconButton(
      onPressed: () => _msg('Viewing client $id'),
      icon: const Icon(
        Icons.visibility_outlined,
        color: Color(0xFF1769E8),
        size: 17,
      ),
      tooltip: 'View',
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

  Widget _details() {
    return _panel(
      'Client Details',
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
                    Icons.business_outlined,
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
                        'ABC Industries',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172A43),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'CL-001 • Brand A • Active',
                        style: TextStyle(fontSize: 9, color: Color(0xFF718096)),
                      ),
                    ],
                  ),
                ),
                _chip('Active'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detail('Contact Person', 'Rajesh Mehta', Icons.person_outline),
          _detail('Email', 'admin@abc.com', Icons.email_outlined),
          _detail('Warehouse', 'WH-A', Icons.warehouse_outlined),
          _detail('Orders', '128', Icons.shopping_cart_outlined),
          _detail('Billing', '₹ 12,84,500', Icons.currency_rupee_rounded),
          _detail('Last Order', '16 Sep 2026', Icons.schedule_outlined),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _msg('Client edit opened.'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _msg('Client portal opened.'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Portal'),
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF27394F),
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
