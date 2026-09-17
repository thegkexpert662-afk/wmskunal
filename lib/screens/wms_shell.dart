import 'package:flutter/material.dart';

import 'audit_logs_screen.dart';
import 'brands_screen.dart';
import 'client_portal_screen.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'dispatch_screen.dart';
import 'employees_screen.dart';
import 'gate_screen.dart';
import 'inbound_screen.dart';
import 'inventory_screen.dart';
import 'invoice_screen.dart';
import 'login_screen.dart';
import 'material_out_screen.dart';
import 'orders_screen.dart';
import 'packing_screen.dart';
import 'picking_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'users_roles_screen.dart';
import 'warehouses_screen.dart';

class WmsShell extends StatefulWidget {
  final bool clientMode;

  const WmsShell({super.key, this.clientMode = false});

  @override
  State<WmsShell> createState() => _WmsShellState();
}

class _WmsShellState extends State<WmsShell> {
  int selected = 0;
  bool collapsed = false;

  final adminItems = const <Map<String, dynamic>>[
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Warehouse', 'icon': Icons.warehouse_outlined},
    {'title': 'Employees', 'icon': Icons.groups_outlined},
    {'title': 'Inventory', 'icon': Icons.inventory_2_outlined},
    {'title': 'Inbound / GRN', 'icon': Icons.move_to_inbox_outlined},
    {'title': 'Outward / Dispatch', 'icon': Icons.local_shipping_outlined},
    {'title': 'Gate In / Out', 'icon': Icons.login_outlined},
    {'title': 'Orders', 'icon': Icons.shopping_cart_outlined},
    {'title': 'Picking', 'icon': Icons.playlist_add_check_outlined},
    {'title': 'Packing', 'icon': Icons.inventory_2_outlined},
    {'title': 'Material Out', 'icon': Icons.outbox_outlined},
    {'title': 'Invoices', 'icon': Icons.receipt_long_outlined},
    {'title': 'Clients', 'icon': Icons.business_outlined},
    {'title': 'Brands', 'icon': Icons.layers_outlined},
    {'title': 'Products', 'icon': Icons.category_outlined},
    {'title': 'Reports', 'icon': Icons.bar_chart_outlined},
    {'title': 'Users & Roles', 'icon': Icons.manage_accounts_outlined},
    {'title': 'Audit Logs', 'icon': Icons.history_outlined},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
    {'title': 'Client Portal', 'icon': Icons.open_in_new_outlined},
  ];

  final clientItems = const <Map<String, dynamic>>[
    {'title': 'Client Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Product Catalogue', 'icon': Icons.category_outlined},
    {'title': 'Place Order', 'icon': Icons.add_shopping_cart_outlined},
    {'title': 'My Orders', 'icon': Icons.shopping_bag_outlined},
    {'title': 'Dispatch Status', 'icon': Icons.local_shipping_outlined},
    {'title': 'Invoices', 'icon': Icons.receipt_long_outlined},
    {'title': 'Notifications', 'icon': Icons.notifications_none_outlined},
    {'title': 'Profile', 'icon': Icons.person_outline},
  ];

  List<Map<String, dynamic>> get items => widget.clientMode ? clientItems : adminItems;

  Widget page() {
    if (widget.clientMode) return const ClientPortalScreen();
    switch (selected) {
      case 0: return const DashboardScreen();
      case 1: return const WarehousesScreen();
      case 2: return const EmployeesScreen();
      case 3: return const InventoryScreen();
      case 4: return const InboundScreen();
      case 5: return const DispatchScreen();
      case 6: return const GateScreen();
      case 7: return const OrdersScreen();
      case 8: return const PickingScreen();
      case 9: return const PackingScreen();
      case 10: return const MaterialOutScreen();
      case 11: return const InvoiceScreen();
      case 12: return const ClientsScreen();
      case 13: return const BrandsScreen();
      case 14: return const ProductsScreen();
      case 15: return const ReportsScreen();
      case 16: return const UsersRolesScreen();
      case 17: return const AuditLogsScreen();
      case 18: return const SettingsScreen();
      case 19: return const ClientPortalScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 800;
    return Scaffold(
      drawer: mobile ? Drawer(child: _menu()) : null,
      body: Row(
        children: [
          if (!mobile) AnimatedContainer(duration: const Duration(milliseconds: 180), width: collapsed ? 72 : 255, child: _sidebar()),
          Expanded(child: Column(children: [_topbar(mobile), Expanded(child: page())])),
        ],
      ),
    );
  }

  Widget _sidebar() => Container(color: const Color(0xFF061D3A), child: SafeArea(child: _menu()));

  Widget _menu() {
    return Container(
      color: const Color(0xFF061D3A),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFF1769D5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 25)),
              if (!collapsed) const Padding(padding: EdgeInsets.only(left: 11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WMS', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('Warehouse Management System', style: TextStyle(color: Color(0xFFB8C9DD), fontSize: 9))])),
            ]),
          ),
          const SizedBox(height: 22),
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: items.length, itemBuilder: (_, i) {
            final active = selected == i;
            return Padding(padding: const EdgeInsets.only(bottom: 4), child: Tooltip(message: items[i]['title'] as String, child: ListTile(dense: true, minLeadingWidth: 25, selected: active, selectedTileColor: const Color(0xFF1769D5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), leading: Icon(items[i]['icon'] as IconData, color: active ? Colors.white : const Color(0xFFD4E0EE), size: 22), title: collapsed ? null : Text(items[i]['title'] as String, style: TextStyle(color: active ? Colors.white : const Color(0xFFE2EAF3), fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w500)), onTap: () { setState(() => selected = i); if (MediaQuery.sizeOf(context).width < 800) Navigator.pop(context); })));
          })),
          if (!collapsed) Container(margin: const EdgeInsets.fromLTRB(18, 0, 18, 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0B2B50), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1C4168))), child: const Row(children: [Icon(Icons.help_outline, color: Colors.white, size: 25), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Need Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), SizedBox(height: 3), Text('Contact Support', style: TextStyle(color: Color(0xFF2F8CFF), fontSize: 11))])])),
          IconButton(onPressed: () => setState(() => collapsed = !collapsed), icon: Icon(collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left, color: Colors.white)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _topbar(bool mobile) {
    final title = items[selected]['title'] as String;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),),
      child: Row(children: [
        if (mobile) Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu))),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF10243E))), if (!mobile) Row(children: [const Text('Dashboard', style: TextStyle(color: Color(0xFF66788E), fontSize: 12)), const Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Icon(Icons.chevron_right, size: 15, color: Color(0xFF9AA8B8))), Text(title, style: const TextStyle(color: Color(0xFF1769D5), fontSize: 12, fontWeight: FontWeight.w600))])])),
        IconButton(tooltip: 'Notifications', onPressed: () { showModalBottomSheet(context: context, builder: (_) => const Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: Icon(Icons.shopping_cart_outlined), title: Text('New order received')), ListTile(leading: Icon(Icons.receipt_long_outlined), title: Text('Invoice generated'))]))); }, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF263B54))),
        const SizedBox(width: 10),
        PopupMenuButton<String>(onSelected: (value) { if (value == 'logout') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }, itemBuilder: (_) => const [PopupMenuItem(value: 'profile', child: Text('Profile')), PopupMenuItem(value: 'logout', child: Text('Logout'))], child: const CircleAvatar(radius: 21, backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.person, color: Color(0xFF1769D5))),),
        if (!mobile) const Padding(padding: EdgeInsets.only(left: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('Admin User', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1A2C43))), SizedBox(height: 2), Text('Administrator', style: TextStyle(fontSize: 11, color: Color(0xFF718198)))])),
        if (!mobile) const Icon(Icons.keyboard_arrow_down, color: Color(0xFF52657A)),
      ]),
    );
  }
}
