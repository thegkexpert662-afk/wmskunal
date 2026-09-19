import 'package:flutter/material.dart';

class AdminPutawayScreen extends StatefulWidget {
  const AdminPutawayScreen({super.key});

  @override
  State<AdminPutawayScreen> createState() => _AdminPutawayScreenState();
}

class _AdminPutawayScreenState extends State<AdminPutawayScreen> {
  final searchController = TextEditingController();
  String status = 'All';
  String warehouse = 'All';
  String zone = 'All';
  int selectedIndex = 0;

  final List<Map<String, dynamic>> tasks = [
    {'put':'PUT-2025-00418','grn':'GRN-2025-00125','product':'Cotton Fabric Roll','sku':'FAB-COT-001','qty':40,'uom':'Roll','warehouse':'Main Warehouse','zone':'A-01','bin':'A01-03-02','status':'Completed'},
    {'put':'PUT-2025-00417','grn':'GRN-2025-00125','product':'Polyester Fabric','sku':'FAB-POL-014','qty':55,'uom':'Roll','warehouse':'Main Warehouse','zone':'A-02','bin':'A02-01-04','status':'In Progress'},
    {'put':'PUT-2025-00416','grn':'GRN-2025-00124','product':'Packing Box Large','sku':'BOX-L-120','qty':85,'uom':'Nos','warehouse':'Ankleshwar WH','zone':'B-01','bin':'B01-02-01','status':'Pending'},
    {'put':'PUT-2025-00415','grn':'GRN-2025-00123','product':'Plastic Container 20L','sku':'CON-20L-002','qty':120,'uom':'Nos','warehouse':'Vilayat Warehouse','zone':'C-03','bin':'C03-04-02','status':'Completed'},
    {'put':'PUT-2025-00414','grn':'GRN-2025-00122','product':'Industrial Tape','sku':'TAPE-48-001','qty':150,'uom':'Nos','warehouse':'Main Warehouse','zone':'B-02','bin':'B02-03-01','status':'Pending'},
    {'put':'PUT-2025-00413','grn':'GRN-2025-00121','product':'Printed Label Roll','sku':'LBL-100-007','qty':95,'uom':'Roll','warehouse':'Delhi Warehouse','zone':'D-01','bin':'D01-01-03','status':'Completed'},
  ];

  List<Map<String, dynamic>> get filtered => tasks.where((t) {
    final q = searchController.text.trim().toLowerCase();
    return (q.isEmpty || t.values.any((v) => v.toString().toLowerCase().contains(q))) &&
        (status == 'All' || t['status'] == status) &&
        (warehouse == 'All' || t['warehouse'] == warehouse) &&
        (zone == 'All' || t['zone'] == zone);
  }).toList();

  @override
  void initState() { super.initState(); searchController.addListener(_refresh); }
  void _refresh() => setState(() {});
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1100;
    final rows = filtered;
    return Container(
      color: const Color(0xFFF7F9FC),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(compact), const SizedBox(height: 18), _stats(compact), const SizedBox(height: 18),
          compact ? Column(children: [_table(rows), const SizedBox(height: 16), _details(rows)]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _table(rows)), const SizedBox(width: 16), SizedBox(width: 310, child: _details(rows))]),
        ]),
      ),
    );
  }

  Widget _header(bool compact) => Row(children: [
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PUT / Putaway', style: TextStyle(color: Color(0xFF122640), fontSize: 25, fontWeight: FontWeight.w900)),
      SizedBox(height: 5), Text('Move received material from staging to warehouse locations.', style: TextStyle(color: Color(0xFF718096), fontSize: 13)),
    ])),
    if (!compact) FilledButton.icon(onPressed: _createPutaway, icon: const Icon(Icons.add_rounded), label: const Text('Create PUT'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1463E8))),
  ]);

  Widget _stats(bool compact) {
    final cards = [
      _stat('Total PUT Tasks', '${tasks.length + 38}', 'All Time', Icons.inventory_2_outlined, const Color(0xFF1769D5), const Color(0xFFEAF3FF)),
      _stat('Pending', '${tasks.where((e) => e['status'] == 'Pending').length + 8}', 'Need Action', Icons.pending_actions_outlined, const Color(0xFFE69A12), const Color(0xFFFFF5E4)),
      _stat('In Progress', '${tasks.where((e) => e['status'] == 'In Progress').length + 4}', 'Currently Moving', Icons.sync_outlined, const Color(0xFF7448D8), const Color(0xFFF0E9FF)),
      _stat('Completed Today', '24', 'Putaway Completed', Icons.check_circle_outline_rounded, const Color(0xFF17A15B), const Color(0xFFE8FAF0)),
    ];
    if (compact) return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.25, children: cards);
    return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 14)]]);
  }

  Widget _stat(String title, String value, String sub, IconData icon, Color iconColor, Color bg) => Container(
    padding: const EdgeInsets.all(15), decoration: _box(), child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: iconColor, size: 28)),
      const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2D45))), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF132A49))), Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF748297)))])),
    ]),
  );

  Widget _table(List<Map<String, dynamic>> rows) => Container(decoration: _box(), child: Column(children: [
    _filters(), const Divider(height: 1),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowHeight: 48, dataRowMinHeight: 55, dataRowMaxHeight: 60, columnSpacing: 23, headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
      columns: const [DataColumn(label: Text('#')),DataColumn(label: Text('PUT No.')),DataColumn(label: Text('GRN No.')),DataColumn(label: Text('Product / SKU')),DataColumn(label: Text('Qty')),DataColumn(label: Text('Warehouse')),DataColumn(label: Text('Zone')),DataColumn(label: Text('Bin')),DataColumn(label: Text('Status')),DataColumn(label: Text('Action'))],
      rows: List.generate(rows.length, (i) { final t = rows[i]; final original = tasks.indexOf(t); return DataRow(selected: selectedIndex == original, cells: [
        DataCell(Text('${i + 1}')), DataCell(Text(t['put'], style: const TextStyle(fontWeight: FontWeight.w700))), DataCell(Text(t['grn'])),
        DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['product'], style: const TextStyle(fontWeight: FontWeight.w600)), Text(t['sku'], style: const TextStyle(fontSize: 10, color: Color(0xFF718096)))])),
        DataCell(Text('${t['qty']} ${t['uom']}')), DataCell(Text(t['warehouse'])), DataCell(Text(t['zone'])), DataCell(Text(t['bin'], style: const TextStyle(fontWeight: FontWeight.w600))), DataCell(_status(t['status'])),
        DataCell(IconButton(onPressed: () => setState(() => selectedIndex = original), tooltip: 'View / Process', icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 18))),
      ]); }),
    )), const Divider(height: 1), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Text('Showing ${rows.length} of ${tasks.length} records', style: const TextStyle(fontSize: 10, color: Color(0xFF718096))), const Spacer(), TextButton(onPressed: () => setState(() {}), child: const Text('Refresh'))]))
  ]));

  Widget _filters() => Padding(padding: const EdgeInsets.all(13), child: Wrap(spacing: 9, runSpacing: 9, children: [
    SizedBox(width: 290, height: 40, child: TextField(controller: searchController, decoration: InputDecoration(hintText: 'Search PUT, GRN, SKU, product, bin...', hintStyle: const TextStyle(fontSize: 10), prefixIcon: const Icon(Icons.search_rounded, size: 18), contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
    _dropdown('Warehouse', warehouse, ['All','Main Warehouse','Ankleshwar WH','Vilayat Warehouse','Delhi Warehouse'], (v) => setState(() => warehouse = v!)),
    _dropdown('Zone', zone, ['All','A-01','A-02','B-01','B-02','C-03','D-01'], (v) => setState(() => zone = v!)),
    _dropdown('Status', status, ['All','Pending','In Progress','Completed'], (v) => setState(() => status = v!)),
  ]));

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => SizedBox(width: 150, height: 40, child: DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 10), contentPadding: const EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), style: const TextStyle(fontSize: 10, color: Color(0xFF42546A), fontWeight: FontWeight.w600), items: values.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged));

  Widget _details(List<Map<String, dynamic>> rows) {
    final t = rows.isNotEmpty ? rows[selectedIndex < rows.length ? selectedIndex : 0] : null;
    if (t == null) return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: const Text('No PUT task selected.'));
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PUT Task Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF162B46))), const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1769E8))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['put'], style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(t['product'], style: const TextStyle(fontSize: 11, color: Color(0xFF718096)))]))])),
      const SizedBox(height: 12), _detail('GRN', t['grn']), _detail('Quantity', '${t['qty']} ${t['uom']}'), _detail('Warehouse', t['warehouse']), _detail('Zone', t['zone']), _detail('Bin Location', t['bin']), _detail('Status', t['status']), const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: t['status'] == 'Completed' ? null : _processSelected, icon: const Icon(Icons.play_arrow_rounded, size: 18), label: Text(t['status'] == 'Completed' ? 'Completed' : 'Process Putaway'))),
    ]));
  }

  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF718096)))), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D304A)))]));
  Widget _status(String value) { final completed = value == 'Completed'; final progress = value == 'In Progress'; final color = completed ? const Color(0xFF14894E) : progress ? const Color(0xFF7448D8) : const Color(0xFFE28C00); final bg = completed ? const Color(0xFFE4F7EC) : progress ? const Color(0xFFF0E9FF) : const Color(0xFFFFF0D8); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800))); }
  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE2E9F1)), boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 14, offset: Offset(0, 5))]);

  void _createPutaway() => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Create PUT'), content: const Text('Select GRN, product, quantity, warehouse, zone and bin to create a putaway task.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')), FilledButton(onPressed: () { Navigator.pop(context); _snack('PUT creation form is ready for backend connection.'); }, child: const Text('Continue'))]));
  void _processSelected() { if (selectedIndex < 0 || selectedIndex >= tasks.length) return; setState(() => tasks[selectedIndex]['status'] = 'Completed'); _snack('Putaway completed.'); }
  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
