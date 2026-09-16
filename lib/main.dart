import 'package:flutter/material.dart';

void main() => runApp(const WmsApp());

class WmsApp extends StatelessWidget {
  const WmsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kopersay WMS',
        theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF4FAFD), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B9ACB))),
        home: const Dashboard(),
      );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selected = 0;
  bool collapsed = false;
  final menu = const <Map<String, dynamic>>[
    {'name': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'name': 'Gate In / Out', 'icon': Icons.login_outlined},
    {'name': 'Inbound / GRN', 'icon': Icons.move_to_inbox_outlined},
    {'name': 'Inventory', 'icon': Icons.inventory_2_outlined},
    {'name': 'Orders', 'icon': Icons.shopping_cart_outlined},
    {'name': 'Picking', 'icon': Icons.playlist_add_check_outlined},
    {'name': 'Material Out', 'icon': Icons.outbox_outlined},
    {'name': 'Dispatch', 'icon': Icons.local_shipping_outlined},
    {'name': 'Invoices', 'icon': Icons.receipt_long_outlined},
    {'name': 'Clients', 'icon': Icons.business_outlined},
    {'name': 'Products', 'icon': Icons.category_outlined},
    {'name': 'Warehouses', 'icon': Icons.warehouse_outlined},
    {'name': 'Reports', 'icon': Icons.bar_chart_outlined},
    {'name': 'Users & Roles', 'icon': Icons.manage_accounts_outlined},
    {'name': 'Settings', 'icon': Icons.settings_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 800;
    return Scaffold(
      drawer: mobile ? Drawer(child: _menu()) : null,
      body: Row(children: [
        if (!mobile) AnimatedContainer(duration: const Duration(milliseconds: 200), width: collapsed ? 72 : 250, child: _sidebar()),
        Expanded(child: Column(children: [_topbar(mobile), Expanded(child: selected == 0 ? _dashboard() : _module())])),
      ]),
    );
  }

  Widget _sidebar() => Container(color: Colors.white, child: SafeArea(child: Column(children: [
    const SizedBox(height: 18),
    Row(children: [const SizedBox(width: 15), Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF09A2D3), Color(0xFF116FA3)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.warehouse_rounded, color: Colors.white)), if (!collapsed) const Padding(padding: EdgeInsets.only(left: 12), child: Text('KOPERSAY\nWMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, height: 1)))]),
    const SizedBox(height: 20), Expanded(child: _menu()), IconButton(onPressed: () => setState(() => collapsed = !collapsed), icon: Icon(collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left)), const SizedBox(height: 10),
  ])));

  Widget _menu() => ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 9), itemCount: menu.length, itemBuilder: (_, i) { final active = selected == i; return ListTile(dense: true, selected: active, selectedTileColor: const Color(0xFFE6F6FC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), leading: Icon(menu[i]['icon'] as IconData, color: active ? const Color(0xFF087EAE) : const Color(0xFF607783)), title: collapsed ? null : Text(menu[i]['name'] as String, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? const Color(0xFF08739F) : const Color(0xFF435A65))), onTap: () { setState(() => selected = i); if (MediaQuery.sizeOf(context).width < 800) Navigator.pop(context); }); });

  Widget _topbar(bool mobile) => Container(height: 72, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE1EDF2)))), child: Row(children: [if (mobile) Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu))), Text(menu[selected]['name'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17323E))), const Spacer(), IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 8), const CircleAvatar(backgroundColor: Color(0xFFDDF2FA), child: Icon(Icons.person_outline, color: Color(0xFF087EAE))), if (!mobile) const Padding(padding: EdgeInsets.only(left: 10), child: Text('Admin User', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))) ]);

  Widget _dashboard() => LayoutBuilder(builder: (_, c) => SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Good Evening, Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF17323E))), const SizedBox(height: 5), const Text('Warehouse activity overview for today.', style: TextStyle(color: Color(0xFF6C818B))), const SizedBox(height: 24), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: c.maxWidth < 700 ? 2 : 4, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.1, children: [_stat('Total Clients', '24', Icons.business_outlined), _stat('Warehouses', '08', Icons.warehouse_outlined), _stat('Today Inbound', '128', Icons.move_to_inbox_outlined), _stat('Today Outbound', '96', Icons.local_shipping_outlined)]), const SizedBox(height: 24), c.maxWidth < 1000 ? Column(children: [_operations(), const SizedBox(height: 20), _orders()]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _operations()), const SizedBox(width: 20), Expanded(child: _orders())]), const SizedBox(height: 24), _inventory() ]));

  Widget _stat(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE8F7FC), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF087EAE))), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF70848D))), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const Text('Updated today', style: TextStyle(fontSize: 9, color: Color(0xFF1490BA)))])]));

  Widget _operations() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Warehouse Operations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Card(child: Column(children: [_row('Inbound / GRN', '128', Icons.move_to_inbox_outlined), _row('Pending Orders', '42', Icons.shopping_cart_outlined), _row('Picking', '31', Icons.playlist_add_check_outlined), _row('Dispatch Ready', '18', Icons.local_shipping_outlined)]))]);
  Widget _row(String title, String value, IconData icon) => ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFEAF7FB), child: Icon(icon, color: const Color(0xFF087EAE), size: 20)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), trailing: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)));

  Widget _orders() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Recent Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Card(child: Column(children: [_order('ORD-10284', 'ABC Industries', 'Processing'), _order('ORD-10283', 'Metro Retail', 'Picking'), _order('ORD-10282', 'Prime Traders', 'Dispatched'), _order('ORD-10281', 'Global Parts', 'Pending')]))]);
  Widget _order(String id, String client, String status) => ListTile(leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF087EAE)), title: Text(id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Text(client, style: const TextStyle(fontSize: 11)), trailing: Text(status, style: const TextStyle(color: Color(0xFF087EAE), fontSize: 10, fontWeight: FontWeight.w700)));
  Widget _inventory() => Card(child: Padding(padding: const EdgeInsets.all(22), child: Wrap(spacing: 45, runSpacing: 18, children: const [_Mini('12,840', 'Stock Items'), _Mini('16', 'Low Stock'), _Mini('09', 'On Hold'), _Mini('24', 'Total Clients')]));
  Widget _module() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(menu[selected]['icon'] as IconData, size: 70, color: const Color(0xFF0B8DBB)), const SizedBox(height: 16), Text(menu[selected]['name'] as String, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 6), const Text('Module UI will be developed next.', style: TextStyle(color: Color(0xFF71858E)))]));
}

class _Mini extends StatelessWidget { final String value; final String label; const _Mini(this.value, this.label); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF758991)))]); }
