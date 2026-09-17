import 'package:flutter/material.dart';
import 'common_widgets.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final search = TextEditingController();
  String status = 'All';

  final brands = const [
    ['BR-001', 'Brand A', 'BRA', '12', '04', 'Manager A', 'Active', '₹ 18,42,500'],
    ['BR-002', 'Brand B', 'BRB', '12', '04', 'Manager B', 'Active', '₹ 14,76,800'],
    ['BR-003', 'Brand C', 'BRC', '08', '03', 'Manager C', 'Pending', '₹ 8,52,400'],
    ['BR-004', 'Brand D', 'BRD', '05', '02', 'Manager D', 'Inactive', '₹ 4,25,750'],
    ['BR-005', 'Brand E', 'BRE', '03', '01', 'Manager E', 'Active', '₹ 2,78,200'],
  ];

  List<List<String>> get filtered => brands.where((r) {
    final q = search.text.toLowerCase().trim();
    return (q.isEmpty || r.any((v) => v.toLowerCase().contains(q))) &&
        (status == 'All' || r[6] == status);
  }).toList();

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
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
      title: 'Brands',
      subtitle: 'Manage brands, client assignments and warehouse access.',
      actions: [
        FilledButton.icon(
          onPressed: () => _msg('Add Brand form opened.'),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Add Brand'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stats(compact),
          const SizedBox(height: 16),
          if (compact)
            Column(children: [_table(), const SizedBox(height: 14), _details()])
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
    final data = [
      ['Total Brands', '05', 'All Registered', Icons.storefront_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)],
      ['Active Brands', '03', '60% Active', Icons.verified_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)],
      ['Pending', '01', 'Awaiting Approval', Icons.pending_actions_outlined, const Color(0xFFE6A014), const Color(0xFFFFF5E1)],
      ['Inactive', '01', 'Currently Disabled', Icons.store_mall_directory_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)],
      ['Total Billing', '₹ 48,75,650', 'Current Period', Icons.currency_rupee_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)],
    ];
    final cards = data.map((d) => _stat(d[0] as String, d[1] as String, d[2] as String, d[3] as IconData, d[4] as Color, d[5] as Color)).toList();
    if (compact) {
      return GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cards);
    }
    return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 12)]]);
  }

  Widget _stat(String title, String value, String sub, IconData icon, Color color, Color bg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _bold(12)),
            const SizedBox(height: 3),
            FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: _bold(23))),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF738298), fontSize: 10)),
          ])),
        ]),
      );

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1)), boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))]);
  TextStyle _bold(double size) => TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w800);

  Widget _panel(String title, Widget body) => Container(padding: const EdgeInsets.all(15), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _bold(14)), const SizedBox(height: 8), body]));

  Widget _table() => _panel('Brand List', Column(children: [
        _filters(),
        const Divider(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 49,
            dataRowMaxHeight: 55,
            columnSpacing: 24,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFFAFBFD)),
            columns: const [
              DataColumn(label: Text('#')), DataColumn(label: Text('Brand ID')), DataColumn(label: Text('Brand Name')), DataColumn(label: Text('Code')), DataColumn(label: Text('Clients')), DataColumn(label: Text('Warehouses')), DataColumn(label: Text('Manager')), DataColumn(label: Text('Status')), DataColumn(label: Text('Billing')), DataColumn(label: Text('Actions')),
            ],
            rows: List.generate(filtered.length, (i) {
              final r = filtered[i];
              return DataRow(cells: [
                DataCell(Text('${i + 1}')), DataCell(Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700))), DataCell(Text(r[1], style: const TextStyle(fontWeight: FontWeight.w600))), DataCell(Text(r[2])), DataCell(Text(r[3])), DataCell(Text(r[4])), DataCell(Text(r[5])), DataCell(_chip(r[6])), DataCell(Text(r[7])), DataCell(_view(r[0])),
              ]);
            }),
          ),
        ),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Text('Showing 1 to ${filtered.length} of 5 entries', style: const TextStyle(color: Color(0xFF718096), fontSize: 10)), const Spacer(), _page('Prev'), _page('1', true), _page('2'), _page('Next')]))
      ]));

  Widget _filters() => Padding(padding: const EdgeInsets.all(10), child: Wrap(spacing: 8, runSpacing: 8, children: [
        SizedBox(width: 320, height: 40, child: TextField(controller: search, decoration: InputDecoration(hintText: 'Search brand, code or manager...', hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8290A2)), prefixIcon: const Icon(Icons.search_rounded, size: 18), contentPadding: const EdgeInsets.symmetric(vertical: 9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDCE4EE))))),
        _drop(status, const ['All', 'Active', 'Pending', 'Inactive'], (v) => setState(() => status = v!), 'Status'),
        OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.filter_alt_outlined, size: 16), label: const Text('Filter'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
        OutlinedButton.icon(onPressed: () => _msg('Brand list exported successfully.'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
      ]));

  Widget _drop(String value, List<String> list, ValueChanged<String?> change, String label) => Container(height: 40, width: 130, padding: const EdgeInsets.symmetric(horizontal: 9), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDCE4EE)), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16), style: const TextStyle(fontSize: 10, color: Color(0xFF42546A), fontWeight: FontWeight.w600), items: list.map((x) => DropdownMenuItem(value: x, child: Text(x == 'All' ? '$label: All' : x))).toList(), onChanged: change)));

  Widget _chip(String s) { final active = s == 'Active'; final pending = s == 'Pending'; final c = active ? const Color(0xFF14894E) : pending ? const Color(0xFFE28C00) : const Color(0xFFD92F4B); final bg = active ? const Color(0xFFE4F7EC) : pending ? const Color(0xFFFFF0D8) : const Color(0xFFFFE5EA); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(s, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w800))); }
  Widget _view(String id) => IconButton(onPressed: () => _msg('Viewing brand $id'), icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17), tooltip: 'View');
  Widget _page(String s, [bool active = false]) => Container(margin: const EdgeInsets.only(left: 4), height: 30, constraints: const BoxConstraints(minWidth: 30), alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 7), decoration: BoxDecoration(color: active ? const Color(0xFF1769E8) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF))), child: Text(s, style: TextStyle(color: active ? Colors.white : const Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.w700)));

  Widget _details() => _panel('Brand Details', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10)), child: Row(children: [Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.storefront_outlined, color: Color(0xFF1769E8), size: 25)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Brand A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))), SizedBox(height: 3), Text('BR-001 • BRA • Active', style: TextStyle(fontSize: 9, color: Color(0xFF718096))])), _chip('Active')])),
    const SizedBox(height: 12),
    _detail('Manager', 'Manager A', Icons.person_outline), _detail('Clients', '12', Icons.groups_outlined), _detail('Warehouses', '04', Icons.warehouse_outlined), _detail('Billing', '₹ 18,42,500', Icons.currency_rupee_rounded), _detail('Last Activity', '16 Sep 2026', Icons.schedule_outlined),
    const Divider(height: 22),
    Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _msg('Brand edit opened.'), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _msg('Brand clients opened.'), icon: const Icon(Icons.groups_outlined, size: 16), label: const Text('Clients')))]),
  ]));

  Widget _detail(String title, String value, IconData icon) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Icon(icon, size: 16, color: const Color(0xFF718096)), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF718096))),), Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F))]));
  void _msg(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
