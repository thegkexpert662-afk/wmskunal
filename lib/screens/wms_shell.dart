import 'package:flutter/material.dart';

import '../models/app_role.dart';
import 'login_screen.dart';

// Master Admin screens
import 'master_admin/master_dashboard_screen.dart';
import 'master_admin/companies_admin_screen.dart';
import 'master_admin/users_roles_screen.dart';
import 'master_admin/system_settings_screen.dart';
import 'master_admin/security_audit_screen.dart';
import 'master_admin/technical_support_screen.dart';
import 'master_admin/device_authentication_screen.dart';

// Admin screens
import 'admin/dashboard_screen.dart';
import 'admin/inbound_screen.dart';
import 'admin/putaway_screen.dart';
import 'admin/clients_screen.dart';
import 'admin/products_screen.dart';
import 'admin/orders_screen.dart';
import 'admin/picking_screen.dart';
import 'admin/packing_screen.dart';
import 'admin/dispatch_screen.dart';
import 'admin/invoice_screen.dart';
import 'admin/stock_mis_screen.dart';
import 'admin/profile_screen.dart';
import 'admin/reports_screen.dart';

// Client screens
import 'client/dashboard_screen.dart';
import 'client/product_catalogue_screen.dart';
import 'client/place_order_screen.dart';
import 'client/my_orders_screen.dart';
import 'client/track_dispatch_screen.dart';
import 'client/my_invoices_screen.dart';
import 'client/profile_screen.dart';

class WmsShell extends StatefulWidget {
  final AppRole role;

  const WmsShell({super.key, required this.role});

  @override
  State<WmsShell> createState() => _WmsShellState();
}

class _WmsShellState extends State<WmsShell> {
  int selected = 0;
  bool collapsed = false;

  static const adminItems = <Map<String, dynamic>>[
    {'title': 'Inward / GRN', 'icon': Icons.move_to_inbox_outlined},
    {'title': 'PUT', 'icon': Icons.inventory_2_outlined},
    {'title': 'Clients', 'icon': Icons.business_outlined},
    {'title': 'Products', 'icon': Icons.category_outlined},
    {'title': 'Orders', 'icon': Icons.shopping_cart_outlined},
    {'title': 'Picking', 'icon': Icons.playlist_add_check_outlined},
    {'title': 'Packing', 'icon': Icons.inventory_2_outlined},
    {'title': 'Dispatch', 'icon': Icons.local_shipping_outlined},
    {'title': 'Invoices', 'icon': Icons.receipt_long_outlined},
    {'title': 'Stock / Excel MIS', 'icon': Icons.table_chart_outlined},
    {'title': 'Profile', 'icon': Icons.person_outline},
    {'title': 'Reports', 'icon': Icons.bar_chart_outlined},
  ];

  static const clientItems = <Map<String, dynamic>>[
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Product Catalogue', 'icon': Icons.category_outlined},
    {'title': 'Place Order', 'icon': Icons.add_shopping_cart_outlined},
    {'title': 'My Orders', 'icon': Icons.shopping_bag_outlined},
    {'title': 'Track Dispatch', 'icon': Icons.local_shipping_outlined},
    {'title': 'My Invoices', 'icon': Icons.receipt_long_outlined},
    {'title': 'Profile', 'icon': Icons.person_outline},
  ];

  static const masterItems = <Map<String, dynamic>>[
    {'title': 'Technical / System Management', 'icon': Icons.admin_panel_settings_outlined},
    {'title': 'Companies / Admin Management', 'icon': Icons.business_outlined},
    {'title': 'Users & Roles', 'icon': Icons.manage_accounts_outlined},
    {'title': 'System Settings', 'icon': Icons.settings_outlined},
    {'title': 'Security / Audit', 'icon': Icons.security_outlined},
    {'title': 'Technical Support', 'icon': Icons.support_agent_outlined},
    {'title': 'Device Authentication', 'icon': Icons.devices_outlined},
  ];

  List<Map<String, dynamic>> get items {
    if (widget.role == AppRole.masterAdmin) return masterItems;
    if (widget.role == AppRole.client) return clientItems;
    return adminItems;
  }

  Widget page() {
    if (widget.role == AppRole.masterAdmin) {
      switch (selected) {
        case 0: return const MasterDashboardScreen();
        case 1: return const CompaniesAdminScreen();
        case 2: return const MasterUsersRolesScreen();
        case 3: return const MasterSystemSettingsScreen();
        case 4: return const MasterSecurityAuditScreen();
        case 5: return const TechnicalSupportScreen();
        case 6: return const DeviceAuthenticationScreen();
        default: return const MasterDashboardScreen();
      }
    }

    if (widget.role == AppRole.client) {
      switch (selected) {
        case 0: return const ClientDashboardScreen();
        case 1: return const ClientProductCatalogueScreen();
        case 2: return const ClientPlaceOrderScreen();
        case 3: return const ClientMyOrdersScreen();
        case 4: return const ClientTrackDispatchScreen();
        case 5: return const ClientMyInvoicesScreen();
        case 6: return const ClientProfileScreen();
        default: return const ClientDashboardScreen();
      }
    }

    switch (selected) {
      case 0: return const AdminInboundScreen();
      case 1: return const AdminPutawayScreen();
      case 2: return const AdminClientsScreen();
      case 3: return const AdminProductsScreen();
      case 4: return const AdminOrdersScreen();
      case 5: return const AdminPickingScreen();
      case 6: return const AdminPackingScreen();
      case 7: return const AdminDispatchScreen();
      case 8: return const AdminInvoiceScreen();
      case 9: return const AdminStockMisScreen();
      case 10: return const AdminProfileScreen();
      case 11: return const AdminReportsScreen();
      default: return const AdminDashboardScreen();
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
              children: [_topbar(mobile), Expanded(child: page())],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() => Container(
        color: const Color(0xFF061D3A),
        child: SafeArea(child: _menu()),
      );

  Widget _menu() {
    return Container(
      color: const Color(0xFF061D3A),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1769D5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warehouse_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                if (!collapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KOPERSAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.role.label,
                          style: const TextStyle(
                            color: Color(0xFFB8C9DD),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final active = selected == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Tooltip(
                    message: items[i]['title'] as String,
                    child: ListTile(
                      dense: true,
                      minLeadingWidth: 25,
                      selected: active,
                      selectedTileColor: const Color(0xFF1769D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      leading: Icon(
                        items[i]['icon'] as IconData,
                        color: active
                            ? Colors.white
                            : const Color(0xFFD4E0EE),
                        size: 22,
                      ),
                      title: collapsed
                          ? null
                          : Text(
                              items[i]['title'] as String,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : const Color(0xFFE2EAF3),
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
          if (!collapsed)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Technical Support',
                    style: TextStyle(
                      color: Color(0xFFB8C9DD),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () => setState(() => collapsed = !collapsed),
            icon: Icon(
              collapsed
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
              color: Colors.white,
            ),
          ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10243E),
                  ),
                ),
                if (!mobile)
                  Text(
                    widget.role.label,
                    style: const TextStyle(
                      color: Color(0xFF1769D5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF263B54),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
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
              radius: 21,
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(
                Icons.person,
                color: Color(0xFF1769D5),
              ),
            ),
          ),
          if (!mobile)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.role.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF1A2C43),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Kopersay WMS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF718198),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
