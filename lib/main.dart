import 'package:flutter/material.dart';

void main() => runApp(const KopersayWmsApp());

const blue = Color(0xFF0B8FBD);
const darkBlue = Color(0xFF075B7A);
const paleBlue = Color(0xFFEAF8FC);
const pageBg = Color(0xFFF4FAFD);

class KopersayWmsApp extends StatelessWidget {
  const KopersayWmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopersay WMS',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD7E7ED)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool clientLogin = false;
  bool obscure = true;
  final email = TextEditingController(text: 'admin@kopersay.com');
  final password = TextEditingController(text: '123456');

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        final compact = c.maxWidth < 850;
        return Row(children: [
          if (!compact)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF087FA9), Color(0xFF064F70)],
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(55),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warehouse_rounded, color: Colors.white, size: 70),
                      SizedBox(height: 24),
                      Text('KOPERSAY WMS', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Text('Warehouse Management System', style: TextStyle(color: Color(0xFFDDF7FF), fontSize: 18)),
                      SizedBox(height: 30),
                      Text('Inbound • Inventory • Orders • Picking • Dispatch • Billing', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.warehouse_rounded, color: blue, size: 45),
                        const SizedBox(height: 14),
                        Text(clientLogin ? 'Client Portal Login' : 'WMS Admin Login', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 7),
                        Text(clientLogin ? 'Access your company orders, stock and invoices.' : 'Sign in to manage warehouse operations.', style: const TextStyle(color: Color(0xFF70858F))),
                        const SizedBox(height: 24),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_outlined)),
                            ButtonSegment(value: true, label: Text('Client'), icon: Icon(Icons.business_outlined)),
                          ],
                          selected: {clientLogin},
                          onSelectionChanged: (v) => setState(() => clientLogin = v.first),
                        ),
                        const SizedBox(height: 20),
                        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: clientLogin ? 'Client Email' : 'Email', prefixIcon: const Icon(Icons.email_outlined))),
                        const SizedBox(height: 14),
                        TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                        const SizedBox(height: 22),
                        SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: () {
                          if (email.text.trim().isEmpty || password.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and password are required.')));
                            return;
                          }
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WmsShell(clientMode: clientLogin)));
                        }, icon: const Icon(Icons.login), label: const Text('Sign In'))),
                        const SizedBox(height: 14),
                        Center(child: TextButton(onPressed: () {}, child: const Text('Forgot password?'))),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class WmsShell extends StatefulWidget {
  final bool clientMode;
  const WmsShell({super.key, this.clientMode = false});
  @override
  State<WmsShell> createState() => _WmsShellState();
}

class _WmsShellState extends State<WmsShell> {
  int selected = 0;
  bool collapsed = false;

  final adminMenu = const [
    ['Dashboard', Icons.dashboard_outlined],
    ['Gate In / Out', Icons.login_outlined],
    ['Inbound / GRN', Icons.move_to_inbox_outlined],
    ['Inventory', Icons.inventory_2_outlined],
    ['Orders', Icons.shopping_cart_outlined],
    ['Picking', Icons.playlist_add_check_outlined],
    ['Material Out', Icons.outbox_outlined],
    ['Dispatch', Icons.local_shipping_outlined],
    ['Invoices', Icons.receipt_long_outlined],
    ['Clients', Icons.business_outlined],
    ['Brands', Icons.layers_outlined],
    ['Products', Icons.category_outlined],
    ['Warehouses', Icons.warehouse_outlined],
    ['Reports', Icons.bar_chart_outlined],
    ['Users & Roles', Icons.manage_accounts_outlined],
    ['Audit Logs', Icons.history_outlined],
    ['Settings', Icons.settings_outlined],
    ['Client Portal', Icons.open_in_new_outlined],
  ];

  final clientMenu = const [
    ['Client Dashboard', Icons.dashboard_outlined],
    ['Product Catalogue', Icons.category_outlined],
    ['Place Order', Icons.add_shopping_cart_outlined],
    ['My Orders', Icons.shopping_bag_outlined],
    ['Dispatch Status', Icons.local_shipping_outlined],
    ['Invoices', Icons.receipt_long_outlined],
    ['Notifications', Icons.notifications_none_outlined],
    ['Profile', Icons.person_outline],
  ];

  List<List<dynamic>> get menu => widget.clientMode ? clientMenu : adminMenu;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 800;
    if (selected >= menu.length) selected = 0;
    return Scaffold(
      drawer: mobile ? Drawer(child: _sidebarContent()) : null,
      body: Row(children: [
        if (!mobile) AnimatedContainer(duration: const Duration(milliseconds: 180), width: collapsed ? 74 : 255, child: _sidebar()),
        Expanded(child: Column(children: [
          _topbar(mobile),
          Expanded(child: _page()),
        ])),
      ]),
    );
  }

  Widget _sidebar() => Container(color: Colors.white, child: SafeArea(child: _sidebarContent()));

  Widget _sidebarContent() => Column(children: [
    const SizedBox(height: 18),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF08A4D7), Color(0xFF075C86)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.warehouse_rounded, color: Colors.white)),
        if (!collapsed) const Padding(padding: EdgeInsets.only(left: 12), child: Text('KOPERSAY\nWMS', style: TextStyle(fontSize: 17, height: 1, fontWeight: FontWeight.w900))),
      ]),
    ),
    const SizedBox(height: 22),
    if (!widget.clientMode && !collapsed) const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Align(alignment: Alignment.centerLeft, child: Text('WORKSPACE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8A9BA3)))),
    Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 9), itemCount: menu.length, itemBuilder: (_, i) {
      final active = i == selected;
      return Padding(padding: const EdgeInsets.only(bottom: 3), child: Tooltip(message: menu[i][0] as String, child: ListTile(
        dense: true,
        selected: active,
        selectedTileColor: paleBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(menu[i][1] as IconData, color: active ? darkBlue : const Color(0xFF617781)),
        title: collapsed ? null : Text(menu[i][0] as String, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? darkBlue : const Color(0xFF405761))),
        onTap: () { setState(() => selected = i); if (MediaQuery.sizeOf(context).width < 800) Navigator.pop(context); },
      )));
    })),
    if (!MediaQuery.sizeOf(context).width.isNaN && MediaQuery.sizeOf(context).width >= 800) IconButton(onPressed: () => setState(() => collapsed = !collapsed), icon: Icon(collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left)),
    const SizedBox(height: 8),
  ]);

  Widget _topbar(bool mobile) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFDCEBF0)))),
    child: Row(children: [
      if (mobile) Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu))),
      Expanded(child: Text(menu[selected][0] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF17323E)))),
      IconButton(onPressed: () => _showNotifications(), icon: const Icon(Icons.notifications_none_rounded)),
      const SizedBox(width: 6),
      PopupMenuButton<String>(
        tooltip: 'Account',
        onSelected: (v) { if (v == 'logout') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
        itemBuilder: (_) => const [PopupMenuItem(value: 'profile', child: Text('Profile')), PopupMenuItem(value: 'logout', child: Text('Logout'))],
        child: const CircleAvatar(backgroundColor: Color(0xFFDDF2FA), child: Icon(Icons.person_outline, color: darkBlue)),
      ),
      if (!mobile) Padding(padding: const EdgeInsets.only(left: 10), child: Text(widget.clientMode ? 'Client A1' : 'Admin User', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
    ]),
  );

  Widget _page() {
    if (widget.clientMode) return _clientPage();
    switch (selected) {
      case 0: return _dashboard();
      case 1: return _gatePage();
      case 2: return _inboundPage();
      case 3: return _inventoryPage();
      case 4: return _ordersPage();
      case 5: return _pickingPage();
      case 6: return _materialOutPage();
      case 7: return _dispatchPage();
      case 8: return _invoicesPage();
      case 9: return _clientsPage();
      case 10: return _brandsPage();
      case 11: return _productsPage();
      case 12: return _warehousesPage();
      case 13: return _reportsPage();
      case 14: return _usersPage();
      case 15: return _auditPage();
      case 16: return _settingsPage();
      case 17: return _clientPage();
      default: return _dashboard();
    }
  }

  Widget _content({required String title, String? subtitle, required Widget child, List<Widget> actions = const []}) => LayoutBuilder(builder: (context, c) => SingleChildScrollView(padding: EdgeInsets.all(c.maxWidth < 600 ? 16 : 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF17323E))), if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text(subtitle, style: const TextStyle(color: Color(0xFF70858F))))])), if (actions.isNotEmpty) Wrap(spacing: 8, children: actions)]),
    const SizedBox(height: 22), child,
  ])));

  Widget _dashboard() => _content(title: 'Good Evening, Admin', subtitle: 'Warehouse activity overview and operational control center.', child: Column(children: [
    LayoutBuilder(builder: (_, c) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: c.maxWidth < 600 ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: c.maxWidth < 600 ? 1.45 : 2.05, children: [
      _stat('Total Clients', '24', Icons.business_outlined, '+3 this month'),
      _stat('Warehouses', '08', Icons.warehouse_outlined, '2 active today'),
      _stat('Today Inbound', '128', Icons.move_to_inbox_outlined, '18 GRN pending'),
      _stat('Today Outbound', '96', Icons.local_shipping_outlined, '18 ready to dispatch'),
    ])),
    const SizedBox(height: 20),
    LayoutBuilder(builder: (_, c) => c.maxWidth < 950 ? Column(children: [_operations(), const SizedBox(height: 20), _recentOrders()]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _operations()), const SizedBox(width: 18), Expanded(child: _recentOrders())])),
    const SizedBox(height: 20),
    _sectionCard(title: 'Inventory Snapshot', child: Wrap(spacing: 55, runSpacing: 22, children: const [_Mini('12,840', 'Stock Items'), _Mini('16', 'Low Stock'), _Mini('09', 'Quality Hold'), _Mini('1,284', 'Available Qty'), _Mini('24', 'Active Clients')]))
  ]));

  Widget _stat(String title, String value, IconData icon, String foot) => Card(child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: paleBlue, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: darkBlue)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF70848D))), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), Text(foot, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: blue))]))]));

  Widget _operations() => _sectionCard(title: 'Warehouse Operations', child: Column(children: [_operationRow('Inbound / GRN', '128', Icons.move_to_inbox_outlined), _operationRow('Pending Orders', '42', Icons.shopping_cart_outlined), _operationRow('Picking In Progress', '31', Icons.playlist_add_check_outlined), _operationRow('Dispatch Ready', '18', Icons.local_shipping_outlined)]));

  Widget _operationRow(String title, String value, IconData icon) => ListTile(leading: CircleAvatar(backgroundColor: paleBlue, child: Icon(icon, color: darkBlue, size: 20)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), trailing: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)));

  Widget _recentOrders() => _sectionCard(title: 'Recent Orders', child: Column(children: [_orderRow('ORD-10284', 'ABC Industries', 'Processing'), _orderRow('ORD-10283', 'Metro Retail', 'Picking'), _orderRow('ORD-10282', 'Prime Traders', 'Dispatched'), _orderRow('ORD-10281', 'Global Parts', 'Pending')]));

  Widget _orderRow(String id, String client, String status) => ListTile(leading: const Icon(Icons.receipt_long_outlined, color: darkBlue), title: Text(id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Text(client, style: const TextStyle(fontSize: 11)), trailing: _status(status));

  Widget _status(String value) { final color = value == 'Dispatched' || value == 'Available' || value == 'Active' ? Colors.green.shade700 : value == 'Pending' || value == 'On Hold' ? Colors.orange.shade800 : blue; return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)), child: Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800))); }

  Widget _sectionCard({required String title, required Widget child, Widget? trailing}) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))), if (trailing != null) trailing]), const SizedBox(height: 12), child])));

  Widget _tableCard({required List<String> headers, required List<List<String>> rows, List<int> statusColumns = const []}) => Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(paleBlue), columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.w800)))).toList(), rows: rows.map((r) => DataRow(cells: List.generate(r.length, (i) => DataCell(statusColumns.contains(i) ? _status(r[i]) : Text(r[i], style: const TextStyle(fontSize: 12)))))).toList())));

  Widget _filterBar({String hint = 'Search...', required VoidCallback onAdd, String addLabel = 'Add New'}) => Wrap(spacing: 10, runSpacing: 10, children: [SizedBox(width: 270, child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hint))), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list), label: const Text('Filter')), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel))]);

  Widget _gatePage() => _content(title: 'Gate In / Out', subtitle: 'Vehicle entry, exit and gate movement records.', actions: [FilledButton.icon(onPressed: () => _addDialog('Gate Entry', ['Vehicle No', 'Driver Name', 'Client', 'Purpose']), icon: const Icon(Icons.add), label: const Text('Gate Entry'))], child: Column(children: [_summaryStrip([['Today In', '34'], ['Today Out', '28'], ['At Gate', '06'], ['Pending', '04']]), const SizedBox(height: 18), _tableCard(headers: const ['Gate ID', 'Vehicle No', 'Client', 'Type', 'Time', 'Status'], rows: const [['GT-0081', 'MH04AB1234', 'ABC Industries', 'Inward', '09:12 AM', 'Inside'], ['GT-0080', 'GJ16XY7821', 'Prime Traders', 'Outward', '10:30 AM', 'Exited'], ['GT-0079', 'MH43CD2211', 'Metro Retail', 'Inward', '11:05 AM', 'Inside'], ['GT-0078', 'GJ05KL9910', 'Global Parts', 'Outward', '12:15 PM', 'Pending']], statusColumns: const [5])])));

  Widget _inboundPage() => _content(title: 'Inbound / GRN', subtitle: 'Receive material, create GRN and move approved stock to inventory.', actions: [FilledButton.icon(onPressed: () => _addDialog('Create GRN', ['Supplier / Client', 'PO Number', 'Vehicle No', 'Material', 'Quantity']), icon: const Icon(Icons.add), label: const Text('Create GRN'))], child: Column(children: [_summaryStrip([['GRN Today', '128'], ['Pending QC', '12'], ['Pending Approval', '06'], ['Completed', '110']]), const SizedBox(height: 18), _tableCard(headers: const ['GRN No', 'Client', 'PO No', 'Material', 'Qty', 'Date', 'Status'], rows: const [['GRN-24081', 'ABC Industries', 'PO-8831', 'RM-1001', '500', '16 Sep 2026', 'Approved'], ['GRN-24080', 'Metro Retail', 'PO-8830', 'FG-2022', '320', '16 Sep 2026', 'QC Hold'], ['GRN-24079', 'Prime Traders', 'PO-8829', 'RM-4010', '760', '16 Sep 2026', 'Pending'], ['GRN-24078', 'Global Parts', 'PO-8828', 'PK-1110', '180', '15 Sep 2026', 'Approved']], statusColumns: const [6])])));

  Widget _inventoryPage() => _content(title: 'Inventory', subtitle: 'Real-time stock view by client, warehouse, SKU and batch.', actions: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined), label: const Text('Export'))], child: Column(children: [_filterBar(hint: 'Search SKU / material / batch...', addLabel: 'Stock Transfer', onAdd: () => _addDialog('Stock Transfer', ['From Warehouse', 'To Warehouse', 'SKU', 'Quantity'])), const SizedBox(height: 18), _tableCard(headers: const ['SKU', 'Material', 'Client', 'Warehouse', 'Batch', 'Qty', 'UOM', 'Status'], rows: const [['SKU-1001', 'Polymer Resin', 'ABC Industries', 'WH-A', 'B24091', '2,450', 'KG', 'Available'], ['SKU-1002', 'Packaging Box', 'Metro Retail', 'WH-B', 'B24092', '1,280', 'PCS', 'Available'], ['SKU-1003', 'Chemical RM', 'Prime Traders', 'WH-A', 'B24088', '760', 'KG', 'On Hold'], ['SKU-1004', 'Finished Goods', 'Global Parts', 'WH-C', 'B24077', '320', 'PCS', 'Low Stock']], statusColumns: const [7])])));

  Widget _ordersPage() => _content(title: 'Client Orders', subtitle: 'Manage client purchase requests from acceptance to dispatch.', actions: [FilledButton.icon(onPressed: () => _addDialog('Create Order', ['Client', 'Product / SKU', 'Quantity', 'Required Date']), icon: const Icon(Icons.add), label: const Text('New Order'))], child: Column(children: [_summaryStrip([['New', '12'], ['Processing', '24'], ['Picking', '18'], ['Ready', '08']]), const SizedBox(height: 18), _tableCard(headers: const ['Order ID', 'Client', 'Items', 'Qty', 'Order Date', 'Required', 'Status'], rows: const [['ORD-10284', 'ABC Industries', '04', '580', '16 Sep', '17 Sep', 'Processing'], ['ORD-10283', 'Metro Retail', '08', '1,240', '16 Sep', '18 Sep', 'Picking'], ['ORD-10282', 'Prime Traders', '03', '760', '15 Sep', '17 Sep', 'Dispatched'], ['ORD-10281', 'Global Parts', '06', '420', '15 Sep', '19 Sep', 'Pending']], statusColumns: const [6])])));

  Widget _pickingPage() => _content(title: 'Picking', subtitle: 'Create and execute picking tasks against approved orders.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.playlist_add), label: const Text('Create Pick List'))], child: Column(children: [_summaryStrip([['Pick Lists', '18'], ['Assigned', '12'], ['In Progress', '31'], ['Completed', '86']]), const SizedBox(height: 18), _tableCard(headers: const ['Pick ID', 'Order', 'Client', 'Warehouse', 'Lines', 'Picker', 'Status'], rows: const [['PICK-5012', 'ORD-10284', 'ABC Industries', 'WH-A', '12', 'Rahul', 'In Progress'], ['PICK-5011', 'ORD-10283', 'Metro Retail', 'WH-B', '18', 'Amit', 'Assigned'], ['PICK-5010', 'ORD-10282', 'Prime Traders', 'WH-A', '08', 'Suresh', 'Completed'], ['PICK-5009', 'ORD-10281', 'Global Parts', 'WH-C', '11', '-', 'Pending']], statusColumns: const [6])])));

  Widget _materialOutPage() => _content(title: 'Material Out', subtitle: 'Verify picked material and approve outward movement.', actions: [FilledButton.icon(onPressed: () => _addDialog('Material Out', ['Order ID', 'Pick ID', 'Vehicle No', 'Quantity']), icon: const Icon(Icons.add), label: const Text('Create Material Out'))], child: _tableCard(headers: const ['MO No', 'Order ID', 'Client', 'Qty', 'Vehicle', 'Created', 'Status'], rows: const [['MO-4008', 'ORD-10284', 'ABC Industries', '580', 'MH04AB1234', '16 Sep', 'Approved'], ['MO-4007', 'ORD-10283', 'Metro Retail', '1,240', 'MH43CD2211', '16 Sep', 'Ready'], ['MO-4006', 'ORD-10282', 'Prime Traders', '760', 'GJ16XY7821', '15 Sep', 'Dispatched'], ['MO-4005', 'ORD-10281', 'Global Parts', '420', '-', '15 Sep', 'Pending']], statusColumns: const [6]));

  Widget _dispatchPage() => _content(title: 'Dispatch', subtitle: 'Dispatch confirmation, vehicle details and gate-out workflow.', actions: [FilledButton.icon(onPressed: () => _addDialog('Dispatch', ['Order ID', 'Transporter', 'Vehicle No', 'LR / AWB No']), icon: const Icon(Icons.local_shipping_outlined), label: const Text('Create Dispatch'))], child: Column(children: [_summaryStrip([['Ready', '18'], ['Dispatched Today', '96'], ['In Transit', '42'], ['Delivered', '36']]), const SizedBox(height: 18), _tableCard(headers: const ['Dispatch ID', 'Order', 'Client', 'Vehicle', 'LR No', 'Date', 'Status'], rows: const [['DSP-7018', 'ORD-10284', 'ABC Industries', 'MH04AB1234', 'LR-90081', '16 Sep', 'Ready'], ['DSP-7017', 'ORD-10283', 'Metro Retail', 'MH43CD2211', 'LR-90080', '16 Sep', 'In Transit'], ['DSP-7016', 'ORD-10282', 'Prime Traders', 'GJ16XY7821', 'LR-90079', '15 Sep', 'Dispatched'], ['DSP-7015', 'ORD-10281', 'Global Parts', 'MH14EF5555', 'LR-90078', '15 Sep', 'Delivered']], statusColumns: const [6])])));

  Widget _invoicesPage() => _content(title: 'Invoices', subtitle: 'Invoice generation, PDF download and client billing history.', actions: [FilledButton.icon(onPressed: () => _addDialog('Generate Invoice', ['Order ID', 'Client', 'Invoice Amount', 'Tax']), icon: const Icon(Icons.receipt_long_outlined), label: const Text('Generate Invoice'))], child: _tableCard(headers: const ['Invoice No', 'Client', 'Order', 'Amount', 'Date', 'PDF', 'Email'], rows: const [['INV-2026-081', 'ABC Industries', 'ORD-10284', '₹2,84,500', '16 Sep', 'Ready', 'Sent'], ['INV-2026-080', 'Metro Retail', 'ORD-10283', '₹1,72,800', '16 Sep', 'Ready', 'Sent'], ['INV-2026-079', 'Prime Traders', 'ORD-10282', '₹98,400', '15 Sep', 'Ready', 'Pending'], ['INV-2026-078', 'Global Parts', 'ORD-10281', '₹76,250', '15 Sep', 'Ready', 'Sent']], statusColumns: const [5, 6]));

  Widget _clientsPage() => _content(title: 'Clients', subtitle: 'Client master, contacts, assigned brand and warehouse access.', actions: [FilledButton.icon(onPressed: () => _addDialog('Add Client', ['Client Name', 'Brand', 'Email', 'Phone']), icon: const Icon(Icons.add_business), label: const Text('Add Client'))], child: _tableCard(headers: const ['Client ID', 'Client Name', 'Brand', 'Warehouse', 'Contact', 'Orders', 'Status'], rows: const [['CL-001', 'ABC Industries', 'Brand A', 'WH-A', 'admin@abc.com', '128', 'Active'], ['CL-002', 'Metro Retail', 'Brand A', 'WH-B', 'ops@metro.com', '96', 'Active'], ['CL-003', 'Prime Traders', 'Brand B', 'WH-A', 'store@prime.com', '74', 'Active'], ['CL-004', 'Global Parts', 'Brand B', 'WH-C', 'logistics@global.com', '52', 'Active']], statusColumns: const [6]));

  Widget _brandsPage() => _content(title: 'Brands', subtitle: 'Multi-brand control. Each brand has isolated clients and operational data.', actions: [FilledButton.icon(onPressed: () => _addDialog('Add Brand', ['Brand Name', 'Brand Code', 'Manager Name']), icon: const Icon(Icons.add), label: const Text('Add Brand'))], child: _tableCard(headers: const ['Brand ID', 'Brand Name', 'Code', 'Clients', 'Warehouses', 'Manager', 'Status'], rows: const [['BR-001', 'Brand A', 'BRA', '12', '04', 'Manager A', 'Active'], ['BR-002', 'Brand B', 'BRB', '12', '04', 'Manager B', 'Active']], statusColumns: const [6]));

  Widget _productsPage() => _content(title: 'Products / Material Master', subtitle: 'SKU, UOM, category, client mapping, batch and stock rules.', actions: [FilledButton.icon(onPressed: () => _addDialog('Add Product', ['SKU', 'Product Name', 'Client', 'Category', 'UOM']), icon: const Icon(Icons.add), label: const Text('Add Product'))], child: Column(children: [_filterBar(hint: 'Search SKU / product...', onAdd: () => _addDialog('Add Product', ['SKU', 'Product Name', 'Client', 'Category', 'UOM'])), const SizedBox(height: 18), _tableCard(headers: const ['SKU', 'Product', 'Client', 'Category', 'UOM', 'Min Stock', 'Status'], rows: const [['SKU-1001', 'Polymer Resin', 'ABC Industries', 'Raw Material', 'KG', '500', 'Active'], ['SKU-1002', 'Packaging Box', 'Metro Retail', 'Packaging', 'PCS', '200', 'Active'], ['SKU-1003', 'Chemical RM', 'Prime Traders', 'Raw Material', 'KG', '300', 'Active'], ['SKU-1004', 'Finished Goods', 'Global Parts', 'Finished Goods', 'PCS', '100', 'Active']], statusColumns: const [6])])));

  Widget _warehousesPage() => _content(title: 'Warehouses', subtitle: 'Warehouse, zone, rack, shelf and bin master.', actions: [FilledButton.icon(onPressed: () => _addDialog('Add Warehouse', ['Warehouse Name', 'Code', 'City', 'Manager']), icon: const Icon(Icons.add), label: const Text('Add Warehouse'))], child: _tableCard(headers: const ['WH ID', 'Warehouse', 'Code', 'City', 'Zones', 'Bins', 'Status'], rows: const [['WH-001', 'Main Warehouse', 'WH-A', 'Bhiwandi', '12', '840', 'Active'], ['WH-002', 'North Warehouse', 'WH-B', 'Mumbai', '08', '520', 'Active'], ['WH-003', 'Central Warehouse', 'WH-C', 'Ankleshwar', '10', '620', 'Active'], ['WH-004', 'Client Warehouse', 'WH-D', 'Vilayat', '06', '310', 'Active']], statusColumns: const [6]));

  Widget _reportsPage() => _content(title: 'Reports', subtitle: 'Operational and client-wise reporting center.', child: LayoutBuilder(builder: (_, c) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: c.maxWidth < 650 ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.25, children: [
    _reportTile('Inventory Report', Icons.inventory_2_outlined), _reportTile('Stock Ledger', Icons.history_outlined), _reportTile('GRN Report', Icons.move_to_inbox_outlined), _reportTile('Dispatch Report', Icons.local_shipping_outlined), _reportTile('Order Report', Icons.shopping_cart_outlined), _reportTile('Invoice Report', Icons.receipt_long_outlined), _reportTile('Client Report', Icons.business_outlined), _reportTile('Email Status', Icons.email_outlined),
  ]));

  Widget _reportTile(String title, IconData icon) => Card(child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title generated for demo.'))), child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: blue, size: 34), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('View / Export', style: TextStyle(fontSize: 11, color: Color(0xFF73858D)))]))));

  Widget _usersPage() => _content(title: 'Users & Roles', subtitle: 'Role-based access for company, brand and client users.', actions: [FilledButton.icon(onPressed: () => _addDialog('Add User', ['Full Name', 'Email', 'Role', 'Brand / Client']), icon: const Icon(Icons.person_add_outlined), label: const Text('Add User'))], child: _tableCard(headers: const ['User', 'Email', 'Role', 'Scope', 'Last Login', 'Status'], rows: const [['Admin User', 'admin@kopersay.com', 'Company Admin', 'All Brands', 'Today 07:42 PM', 'Active'], ['Manager A', 'manager.a@kopersay.com', 'Brand Manager', 'Brand A', 'Today 06:31 PM', 'Active'], ['Manager B', 'manager.b@kopersay.com', 'Brand Manager', 'Brand B', 'Today 05:58 PM', 'Active'], ['Client A1', 'admin@abc.com', 'Client User', 'ABC Industries', 'Today 04:22 PM', 'Active']], statusColumns: const [5]));

  Widget _auditPage() => _content(title: 'Audit Logs', subtitle: 'Track important user and operational actions.', child: _tableCard(headers: const ['Time', 'User', 'Module', 'Action', 'Reference', 'Result'], rows: const [['19:32', 'Admin User', 'Orders', 'Accepted Order', 'ORD-10284', 'Success'], ['18:55', 'Manager A', 'Inventory', 'Stock Transfer', 'TR-5012', 'Success'], ['18:31', 'Client A1', 'Orders', 'Placed Order', 'ORD-10284', 'Success'], ['17:48', 'Admin User', 'Invoice', 'Generated PDF', 'INV-2026-081', 'Success']]));

  Widget _settingsPage() => _content(title: 'Settings', subtitle: 'Company, brand, invoice, warehouse and application configuration.', child: Column(children: [
    _settingsCard('Company Settings', Icons.business_outlined, ['Company Name', 'Address', 'GSTIN', 'Support Email']),
    const SizedBox(height: 14), _settingsCard('Invoice Settings', Icons.receipt_long_outlined, ['Invoice Prefix', 'Tax Mode', 'Payment Terms', 'Footer Text']),
    const SizedBox(height: 14), _settingsCard('Warehouse Settings', Icons.warehouse_outlined, ['Default Warehouse', 'Batch Tracking', 'QC Required', 'Barcode Required']),
    const SizedBox(height: 14), _settingsCard('Notification Settings', Icons.notifications_none_outlined, ['New Order', 'Dispatch', 'Invoice Email', 'Low Stock Alert']),
  ]));

  Widget _settingsCard(String title, IconData icon, List<String> fields) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: blue), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]), const SizedBox(height: 15), Wrap(spacing: 12, runSpacing: 12, children: fields.map((f) => SizedBox(width: 240, child: TextField(decoration: InputDecoration(labelText: f)))).toList()), const SizedBox(height: 14), Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title saved.'))), child: const Text('Save Changes')))])));

  Widget _clientPage() => _content(title: widget.clientMode ? 'Client Dashboard' : 'Client Portal Preview', subtitle: 'Client sees only its own company data under its assigned brand.', actions: [if (!widget.clientMode) OutlinedButton.icon(onPressed: () => setState(() => selected = 17), icon: const Icon(Icons.open_in_new), label: const Text('Open Portal'))], child: Column(children: [
    _summaryStrip([['Open Orders', '08'], ['Processing', '05'], ['Dispatched', '12'], ['Invoices', '24']]), const SizedBox(height: 18),
    LayoutBuilder(builder: (_, c) => c.maxWidth < 900 ? Column(children: [_clientActions(), const SizedBox(height: 18), _clientOrders()]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _clientActions()), const SizedBox(width: 18), Expanded(child: _clientOrders())])),
    const SizedBox(height: 18), _sectionCard(title: 'My Invoices', child: _tableCard(headers: const ['Invoice', 'Order', 'Amount', 'Date', 'PDF', 'Email'], rows: const [['INV-2026-081', 'ORD-10284', '₹2,84,500', '16 Sep', 'Download', 'Sent'], ['INV-2026-075', 'ORD-10270', '₹1,18,200', '12 Sep', 'Download', 'Sent'], ['INV-2026-069', 'ORD-10255', '₹86,900', '08 Sep', 'Download', 'Sent']], statusColumns: const [4, 5]))),
  ]));

  Widget _clientActions() => _sectionCard(title: 'Quick Actions', child: Wrap(spacing: 10, runSpacing: 10, children: [FilledButton.icon(onPressed: () => _showOrderDialog(), icon: const Icon(Icons.add_shopping_cart), label: const Text('Place Order')), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.category_outlined), label: const Text('Catalogue')), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.local_shipping_outlined), label: const Text('Track Dispatch'))]));

  Widget _clientOrders() => _sectionCard(title: 'My Recent Orders', child: Column(children: [_orderRow('ORD-10284', '04 items • 580 qty', 'Processing'), _orderRow('ORD-10270', '08 items • 1,240 qty', 'Dispatched'), _orderRow('ORD-10255', '03 items • 760 qty', 'Delivered'), _orderRow('ORD-10241', '06 items • 420 qty', 'Pending')]));

  Widget _summaryStrip(List<List<String>> items) => LayoutBuilder(builder: (_, c) => Wrap(spacing: 12, runSpacing: 12, children: items.map((x) => SizedBox(width: c.maxWidth < 650 ? (c.maxWidth - 12) / 2 : 160, child: Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x[0], style: const TextStyle(fontSize: 11, color: Color(0xFF74868E))), const SizedBox(height: 4), Text(x[1], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkBlue))]))))).toList()));

  Future<void> _addDialog(String title, List<String> fields) async {
    final controllers = fields.map((_) => TextEditingController()).toList();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(children: List.generate(fields.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controllers[i], decoration: InputDecoration(labelText: fields[i])))))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () { if (controllers.any((c) => c.text.trim().isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.'))); return; } Navigator.pop(dialogContext); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title saved successfully.'))); }, child: const Text('Save'))],
    ));
    for (final c in controllers) c.dispose();
  }

  Future<void> _showOrderDialog() async {
    final product = TextEditingController();
    final qty = TextEditingController();
    await showDialog<void>(context: context, builder: (d) => AlertDialog(title: const Text('Place New Order', style: TextStyle(fontWeight: FontWeight.w900)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: product, decoration: const InputDecoration(labelText: 'Product / SKU')), const SizedBox(height: 12), TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))]), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), FilledButton(onPressed: () { if (product.text.trim().isEmpty || qty.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product and quantity are required.'))); return; } Navigator.pop(d); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully.'))); }, child: const Text('Place Order'))]));
    product.dispose();
    qty.dispose();
  }

  void _showNotifications() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), shrinkWrap: true, children: const [ListTile(leading: Icon(Icons.shopping_cart_outlined, color: blue), title: Text('New client order received'), subtitle: Text('ORD-10284 • ABC Industries')), ListTile(leading: Icon(Icons.receipt_long_outlined, color: blue), title: Text('Invoice generated'), subtitle: Text('INV-2026-081')), ListTile(leading: Icon(Icons.inventory_2_outlined, color: Colors.orange), title: Text('Low stock alert'), subtitle: Text('SKU-1004 is below minimum level'))])));
}

class _Mini extends StatelessWidget {
  final String value;
  final String label;
  const _Mini(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkBlue)), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF758991)))]);
}
