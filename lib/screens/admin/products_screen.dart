import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../common_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService service = ProductService.instance;
  final search = TextEditingController();
  String status = 'All';
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      products = await service.getProducts();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _refresh() { if (mounted) setState(() {}); }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    return products.where((p) {
      final active = p['is_active'] == true;
      final statusOk = status == 'All' ||
          (status == 'Active' && active) ||
          (status == 'Inactive' && !active);
      final text = (p['sku'].toString() + ' ' + p['name'].toString() + ' ' +
              (p['hsn_code'] ?? '').toString() + ' ' + p['uom'].toString())
          .toLowerCase();
      return statusOk && (q.isEmpty || text.contains(q));
    }).toList();
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = products.where((p) => p['is_active'] == true).length;
    final inactive = products.length - active;
    return ScreenFrame(
      title: 'Products / Material Master',
      subtitle: 'Manage SKU, HSN, UOM, rate and product status.',
      actions: [
        OutlinedButton.icon(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: () => _openProductDialog(), icon: const Icon(Icons.add_box_outlined), label: const Text('Add Product')),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stats(active, inactive),
        const SizedBox(height: 16),
        _panel('Product List', Column(children: [
          _filters(),
          const Divider(height: 1),
          if (loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            _errorView()
          else if (filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No products found.')))
          else
            HorizontalTableScroller(child: _table()),
        ])),
      ]),
    );
  }

  Widget _stats(int active, int inactive) {
    final cards = [
      _stat('Total Products', products.length.toString(), Icons.inventory_2_outlined),
      _stat('Active Products', active.toString(), Icons.verified_outlined),
      _stat('Inactive Products', inactive.toString(), Icons.inventory_outlined),
    ];
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth < 800) {
        return GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.8, children: cards,
        );
      }
      return Row(children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ]);
    });
  }

  Widget _stat(String title, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _box(),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF1769E8))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _bold(12)), const SizedBox(height: 4), Text(value, style: _bold(23)),
      ]),
    ]),
  );

  Widget _filters() => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(spacing: 10, runSpacing: 10, children: [
      SizedBox(width: 330, height: 42, child: TextField(
        controller: search,
        decoration: InputDecoration(
          hintText: 'Search SKU, product, HSN or UOM...',
          prefixIcon: const Icon(Icons.search, size: 19),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      )),
      SizedBox(width: 135, height: 42, child: DropdownButtonFormField<String>(
        value: status,
        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        items: const [
          DropdownMenuItem(value: 'All', child: Text('Status: All')),
          DropdownMenuItem(value: 'Active', child: Text('Active')),
          DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
        ],
        onChanged: (v) => setState(() => status = v ?? 'All'),
      )),
    ]),
  );

  Widget _table() => DataTable(
    headingTextStyle: const TextStyle(color: Color(0xFF43546A), fontSize: 11, fontWeight: FontWeight.w800),
    dataTextStyle: const TextStyle(color: Color(0xFF26384F), fontSize: 11),
    headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
    columns: const [
      DataColumn(label: Text('#')), DataColumn(label: Text('SKU')), DataColumn(label: Text('Product Name')),
      DataColumn(label: Text('HSN')), DataColumn(label: Text('UOM')), DataColumn(label: Text('Rate')),
      DataColumn(label: Text('Status')), DataColumn(label: Text('Actions')),
    ],
    rows: List.generate(filtered.length, (i) {
      final p = filtered[i];
      final active = p['is_active'] == true;
      return DataRow(cells: [
        DataCell(Text((i + 1).toString())),
        DataCell(Text(p['sku'].toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
        DataCell(Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text((p['hsn_code'] ?? '-').toString())),
        DataCell(Text(p['uom'].toString())),
        DataCell(Text('₹ ' + p['rate'].toString())),
        DataCell(_chip(active ? 'Active' : 'Inactive')),
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'Edit', onPressed: () => _openProductDialog(product: p), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1769E8))),
          IconButton(
            tooltip: active ? 'Deactivate' : 'Activate',
            onPressed: () => _changeStatus(p),
            icon: Icon(active ? Icons.toggle_on_outlined : Icons.toggle_off_outlined, color: active ? const Color(0xFF16A05D) : const Color(0xFF8A98AA)),
          ),
        ])),
      ]);
    }),
  );

  Future<void> _changeStatus(Map<String, dynamic> product) async {
    final active = product['is_active'] == true;
    try {
      await service.updateStatus(id: product['id'].toString(), isActive: !active);
      _msg(active ? 'Product deactivated successfully.' : 'Product activated successfully.');
      await _load();
    } catch (e) { _msg(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> _openProductDialog({Map<String, dynamic>? product}) async {
    final editing = product != null;
    final sku = TextEditingController(text: product?['sku']?.toString() ?? '');
    final name = TextEditingController(text: product?['name']?.toString() ?? '');
    final description = TextEditingController(text: product?['description']?.toString() ?? '');
    final hsn = TextEditingController(text: product?['hsn_code']?.toString() ?? '');
    final uom = TextEditingController(text: product?['uom']?.toString() ?? '');
    final rate = TextEditingController(text: product?['rate']?.toString() ?? '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editing ? 'Edit Product' : 'Add Product'),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(children: [
          _field(sku, 'SKU', enabled: !editing), _field(name, 'Product Name'),
          _field(description, 'Description', maxLines: 3), _field(hsn, 'HSN Code'),
          _field(uom, 'UOM'), _field(rate, 'Rate', keyboard: const TextInputType.numberWithOptions(decimal: true)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (sku.text.trim().isEmpty || name.text.trim().isEmpty || uom.text.trim().isEmpty) {
              _msg('SKU, Product Name and UOM are required.'); return;
            }
            final parsedRate = double.tryParse(rate.text.trim());
            if (parsedRate == null || parsedRate < 0) { _msg('Enter a valid rate.'); return; }
            try {
              if (editing) {
                await service.updateProduct(id: product['id'].toString(), data: {
                  'name': name.text.trim(),
                  'description': description.text.trim().isEmpty ? null : description.text.trim(),
                  'hsnCode': hsn.text.trim().isEmpty ? null : hsn.text.trim(),
                  'uom': uom.text.trim(), 'rate': parsedRate,
                });
              } else {
                await service.createProduct(
                  sku: sku.text.trim(), name: name.text.trim(),
                  description: description.text.trim().isEmpty ? null : description.text.trim(),
                  hsnCode: hsn.text.trim().isEmpty ? null : hsn.text.trim(),
                  uom: uom.text.trim(), rate: parsedRate,
                );
              }
              if (mounted) Navigator.pop(context, true);
            } catch (e) { _msg(e.toString().replaceFirst('Exception: ', '')); }
          }, child: Text(editing ? 'Update' : 'Create')),
        ],
      ),
    );
    for (final c in [sku, name, description, hsn, uom, rate]) { c.dispose(); }
    if (result == true) {
      _msg(editing ? 'Product updated successfully.' : 'Product created successfully.');
      await _load();
    }
  }

  Widget _field(TextEditingController c, String label, {bool enabled = true, int maxLines = 1, TextInputType? keyboard}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: c, enabled: enabled, maxLines: maxLines, keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(9))),
    ));

  Widget _chip(String value) {
    final active = value == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: active ? const Color(0xFFE4F7EC) : const Color(0xFFFFE5EA), borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: TextStyle(color: active ? const Color(0xFF14894E) : const Color(0xFFD92F4B), fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _errorView() => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(children: [
      const Icon(Icons.cloud_off_outlined, size: 42, color: Color(0xFFD92F4B)),
      const SizedBox(height: 10), Text(error ?? 'Unable to load products.'),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ]),
  );

  Widget _panel(String title, Widget body) => Container(
    padding: const EdgeInsets.all(15), decoration: _box(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _bold(14)), const SizedBox(height: 10), body]),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE1E8F1)),
    boxShadow: const [BoxShadow(color: Color(0x0A18304F), blurRadius: 12, offset: Offset(0, 4))],
  );

  TextStyle _bold(double size) => TextStyle(color: const Color(0xFF162B46), fontSize: size, fontWeight: FontWeight.w800);

  void _msg(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
