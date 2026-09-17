import 'package:flutter/material.dart';

import 'audit_logs_screen.dart';
import 'brands_screen.dart';
import 'client_portal_screen.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'dispatch_screen.dart';
import 'gate_screen.dart';
import 'inbound_screen.dart';
import 'inventory_screen.dart';
import 'invoice_screen.dart';
import 'login_screen.dart';
import 'material_out_screen.dart';
import 'orders_screen.dart';
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
    {'title': 'Gate In / Out', 'icon': Icons.login_outlined},
    {'title': 'Inbound / GRN', 'icon': Icons.move_to_inbox_outlined},
    {'title': 'Inventory', 'icon': Icons.inventory_2_outlined},
    {'title': 'Orders', 'icon': Icons.shopping_cart_outlined},
    {'title': 'Picking', 'icon': Icons.playlist_add_check_outlined},
    {'title': 'Material Out', 'icon': Icons.outbox_outlined},
    {'title': 'Dispatch', 'icon': Icons.local_shipping_outlined},
    {'title': 'Invoices', 'icon': Icons.receipt_long_outlined},
    {'title': 'Clients', 'icon': Icons.business_outlined},
    {'title': 'Brands', 'icon': Icons.layers_outlined},
    {'title': 'Products', 'icon': Icons.category_outlined},
    {'title': 'Warehouses', 'icon': Icons.warehouse_outlined},
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

  List<Map<String, dynamic>> get items =>
      widget.clientMode ? clientItems : adminItems;

  Widget page() {
    if (widget.clientMode) {
      return const ClientPortalScreen();
    }

    switch (selected) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const GateScreen();
      case 2:
        return const InboundScreen();
      case 3:
        return const InventoryScreen();
      case 4:
        return const OrdersScreen();
      case 5:
        return const PickingScreen();
      case 6:
        return const MaterialOutScreen();
      case 7:
        return const DispatchScreen();
      case 8:
        return const InvoiceScreen();
      case 9:
        return const ClientsScreen();
      case 10:
        return const BrandsScreen();
      case 11:
        return const ProductsScreen();
      case 12:
        return const WarehousesScreen();
      case 13:
        return const ReportsScreen();
      case 14:
        return const UsersRolesScreen();
      case 15:
        return const AuditLogsScreen();
      case 16:
        return const SettingsScreen();
      case 17:
        return const ClientPortalScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 800;

    return Scaffold(
      drawer: mobile ? Drawer(child: _menu()) : null,
      body: Row(
        children: [
          if (!mobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: collapsed ? 72 : 255,
              child: _sidebar(),
            ),
          Expanded(
            child: Column(
              children: [
                _topbar(mobile),
                Expanded(child: page()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      color: Colors.white,
      child: SafeArea(child: _menu()),
    );
  }

  Widget _menu() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF08A4D7), Color(0xFF075C86)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warehouse_rounded,
                  color: Colors.white,
                ),
              ),
              if (!collapsed)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'KOPERSAY\nWMS',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final active = selected == i;

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Tooltip(
                  message: items[i]['title'] as String,
                  child: ListTile(
                    dense: true,
                    selected: active,
                    selectedTileColor: const Color(0xFFEAF8FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      items[i]['icon'] as IconData,
                      color: active
                          ? const Color(0xFF075B7A)
                          : const Color(0xFF617781),
                    ),
                    title: collapsed
                        ? null
                        : Text(
                            items[i]['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                    onTap: () {
                      setState(() => selected = i);
                      if (MediaQuery.sizeOf(context).width < 800) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 800)
          IconButton(
            onPressed: () => setState(() => collapsed = !collapsed),
            icon: Icon(
              collapsed
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _topbar(bool mobile) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCEBF0)),
        ),
      ),
      child: Row(
        children: [
          if (mobile)
            Builder(
              builder: (c) => IconButton(
                onPressed: () => Scaffold.of(c).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          Expanded(
            child: Text(
              items[selected]['title'] as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17323E),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.shopping_cart_outlined),
                        title: Text('New order received'),
                      ),
                      ListTile(
                        leading: Icon(Icons.receipt_long_outlined),
                        title: Text('Invoice generated'),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: const CircleAvatar(
              backgroundColor: Color(0xFFDDF2FA),
              child: Icon(
                Icons.person_outline,
                color: Color(0xFF075B7A),
              ),
            ),
          ),
          if (!mobile)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                widget.clientMode ? 'Client A1' : 'Admin User',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
