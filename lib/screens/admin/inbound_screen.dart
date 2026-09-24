import 'package:flutter/material.dart';
import '../../services/inbound_service.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../common_widgets.dart';

class AdminInboundScreen extends StatefulWidget {
  const AdminInboundScreen({super.key});
  @override
  State<AdminInboundScreen> createState() => _AdminInboundScreenState();
}

class _AdminInboundScreenState extends State<AdminInboundScreen> {
  final inbound = InboundService.instance;
  final products = ProductService.instance;
  final warehouses = WarehouseService.instance;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> grns = [];
  List<Map<String, dynamic>> receipts = [];
  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> warehouseList = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await Future.wait([
        inbound.getGrns(), inbound.getProductionReceipts(),
        products.getProducts(), warehouses.getWarehouses(),
      ]);
      if (!mounted) return;
      setState(() {
        grns = data[0]; receipts = data[1];
        productList = data[2]; warehouseList = data[3];
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _newReceipt({required bool production}) async {
    if (productList.isEmpty || warehouseList.where((w) => w['is_active'] == true).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an active warehouse and product first.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _InboundDialog(
        production: production,
        products: productList.where((p) => p['is_active'] == true).toList(),
        warehouses: warehouseList.where((w) => w['is_active'] == true).toList(),
        onSubmit: (data) async {
          if (production) {
            await inbound.createProductionReceipt(
              receiptNo: data['number'],
              productionReference: data['reference'],
              warehouseId: data['warehouseId'],
              items: [data['item']],
            );
          } else {
            await inbound.createGrn(
              grnNo: data['number'],
              supplierName: data['supplier'],
              invoiceNo: data['invoice'],
              warehouseId: data['warehouseId'],
              items: [data['item']],
            );
          }
        },
      ),
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Inbound',
      subtitle: 'Receive material from suppliers or from your own manufacturing process.',
      actions: [
        OutlinedButton.icon(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: () => _newReceipt(production: false), icon: const Icon(Icons.receipt_long_outlined), label: const Text('New GRN')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: () => _newReceipt(production: true), icon: const Icon(Icons.factory_outlined), label: const Text('Production Receipt')),
      ],
      child: loading
          ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
          : error != null
              ? _error()
              : DefaultTabController(
                  length: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const TabBar(tabs: [Tab(text: 'Supplier GRN'), Tab(text: 'Manufacturing Receipt')]),
                    const SizedBox(height: 12),
                    SizedBox(height: 520, child: TabBarView(children: [_list(grns, true), _list(receipts, false)])),
                  ]),
                ),
    );
  }

  Widget _list(List<Map<String, dynamic>> rows, bool grn) {
    if (rows.isEmpty) return const Center(child: Text('No inbound records found.'));
    return HorizontalTableScroller(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('No.')),
          const DataColumn(label: Text('Date')),
          DataColumn(label: Text(grn ? 'Supplier' : 'Production Ref.')),
          const DataColumn(label: Text('Warehouse')),
          const DataColumn(label: Text('Status')),
        ],
        rows: rows.map((r) => DataRow(cells: [
          DataCell(Text((grn ? r['grn_no'] : r['receipt_no'])?.toString() ?? '-')),
          DataCell(Text(_date(r['received_at'] ?? r['created_at']))),
          DataCell(Text((grn ? r['supplier_name'] : r['production_reference'])?.toString() ?? '-')),
          DataCell(Text(r['warehouse']?.toString() ?? '-')),
          DataCell(Chip(label: Text((r['status']?.toString() ?? '-').toUpperCase()), visualDensity: VisualDensity.compact)),
        ])).toList(),
      ),
    );
  }

  String _date(dynamic value) {
    if (value == null) return '-';
    final d = DateTime.tryParse(value.toString());
    if (d == null) return value.toString();
    return d.day.toString().padLeft(2, '0') + '-' +
        d.month.toString().padLeft(2, '0') + '-' + d.year.toString();
  }

  Widget _error() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(error!, textAlign: TextAlign.center),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ]));
}

class _InboundDialog extends StatefulWidget {
  final bool production;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> warehouses;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _InboundDialog({
    required this.production, required this.products,
    required this.warehouses, required this.onSubmit,
  });

  @override
  State<_InboundDialog> createState() => _InboundDialogState();
}

class _InboundDialogState extends State<_InboundDialog> {
  final supplier = TextEditingController();
  final invoice = TextEditingController();
  final reference = TextEditingController();
  final qty = TextEditingController();
  String? warehouseId;
  String? productId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    warehouseId = widget.warehouses.first['id']?.toString();
    productId = widget.products.first['id']?.toString();
  }

  @override
  void dispose() {
    supplier.dispose(); invoice.dispose();
    reference.dispose(); qty.dispose(); super.dispose();
  }

  Future<void> _save() async {
    final q = double.tryParse(qty.text.trim());
    if (warehouseId == null || productId == null || q == null || q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    if (!widget.production && supplier.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier name is required.')));
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSubmit({
        'supplier': supplier.text.trim(),
        'invoice': invoice.text.trim().isEmpty ? null : invoice.text.trim(),
        'reference': reference.text.trim().isEmpty ? null : reference.text.trim(),
        'warehouseId': warehouseId,
        'item': {'productId': productId, 'receivedQty': q},
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.production ? 'Production Receipt' : 'New GRN'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.production) TextField(controller: reference, decoration: const InputDecoration(labelText: 'Production Reference'))
            else ...[
              TextField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier Name *')),
              const SizedBox(height: 10),
              TextField(controller: invoice, decoration: const InputDecoration(labelText: 'Supplier Invoice No.')),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: warehouseId,
              decoration: const InputDecoration(labelText: 'Warehouse *'),
              items: widget.warehouses.map((w) => DropdownMenuItem(
                value: w['id'].toString(), child: Text(w['code'].toString() + ' - ' + w['name'].toString()),
              )).toList(),
              onChanged: saving ? null : (v) => setState(() => warehouseId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: productId,
              decoration: const InputDecoration(labelText: 'Product *'),
              items: widget.products.map((p) => DropdownMenuItem(
                value: p['id'].toString(), child: Text(p['sku'].toString() + ' - ' + p['name'].toString()),
              )).toList(),
              onChanged: saving ? null : (v) => setState(() => productId = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Received Quantity *'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
