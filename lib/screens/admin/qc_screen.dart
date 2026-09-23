import 'package:flutter/material.dart';
import '../../services/qc_service.dart';
import '../common_widgets.dart';

class AdminQcScreen extends StatefulWidget {
  const AdminQcScreen({super.key});
  @override
  State<AdminQcScreen> createState() => _AdminQcScreenState();
}

class _AdminQcScreenState extends State<AdminQcScreen> {
  final service = QcService.instance;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await service.getPending();
      if (mounted) setState(() => items = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _process(Map<String, dynamic> item) async {
    final qty = double.tryParse(item['quantity'].toString()) ?? 0;
    if (qty <= 0) return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _QcDialog(item: item, quantity: qty),
    );
    if (result != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Quality Control',
      subtitle: 'Inspect supplier GRN and manufacturing receipts before putaway.',
      actions: [
        OutlinedButton.icon(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
      ],
      child: loading
          ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : items.isEmpty
                  ? const Center(child: Text('No items are pending for QC.'))
                  : HorizontalTableScroller(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Source')),
                          DataColumn(label: Text('Reference')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Warehouse')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: items.map((item) => DataRow(cells: [
                          DataCell(Text(item['source_type'].toString() == 'grn' ? 'Supplier GRN' : 'Manufacturing')),
                          DataCell(Text(item['reference_no']?.toString() ?? '-')),
                          DataCell(Text((item['sku']?.toString() ?? '') + ' - ' + (item['name']?.toString() ?? ''))),
                          DataCell(Text(item['quantity']?.toString() ?? '-')),
                          DataCell(Text(item['warehouse']?.toString() ?? '-')),
                          DataCell(FilledButton(onPressed: () => _process(item), child: const Text('Inspect'))),
                        ])).toList(),
                      ),
                    ),
    );
  }
}

class _QcDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final double quantity;
  const _QcDialog({required this.item, required this.quantity});
  @override
  State<_QcDialog> createState() => _QcDialogState();
}

class _QcDialogState extends State<_QcDialog> {
  late final TextEditingController inspected;
  late final TextEditingController accepted;
  late final TextEditingController rejected;
  late final TextEditingController remarks;
  String result = 'approved';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    inspected = TextEditingController(text: widget.quantity.toString());
    accepted = TextEditingController(text: widget.quantity.toString());
    rejected = TextEditingController(text: '0');
    remarks = TextEditingController();
  }

  @override
  void dispose() {
    inspected.dispose(); accepted.dispose(); rejected.dispose(); remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final i = double.tryParse(inspected.text) ?? -1;
    final a = double.tryParse(accepted.text) ?? -1;
    final r = double.tryParse(rejected.text) ?? -1;
    if (i <= 0 || a < 0 || r < 0 || a + r > i || i > widget.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check inspected, accepted and rejected quantities.')));
      return;
    }
    setState(() => saving = true);
    try {
      await QcService.instance.process(
        sourceType: widget.item['source_type'].toString(),
        sourceItemId: widget.item['source_item_id'].toString(),
        inspectedQty: i, acceptedQty: a, rejectedQty: r,
        result: result, remarks: remarks.text.trim().isEmpty ? null : remarks.text.trim(),
      );
      if (mounted) Navigator.pop(context, 'saved');
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
      title: Text('QC Inspection - ' + (widget.item['reference_no']?.toString() ?? '')),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Product: ' + (widget.item['name']?.toString() ?? '-')),
            const SizedBox(height: 12),
            TextField(controller: inspected, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Inspected Quantity')),
            const SizedBox(height: 10),
            TextField(controller: accepted, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Accepted Quantity')),
            const SizedBox(height: 10),
            TextField(controller: rejected, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rejected Quantity')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: result,
              decoration: const InputDecoration(labelText: 'QC Result'),
              items: const [
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'partial', child: Text('Partial')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: saving ? null : (v) => setState(() => result = v ?? result),
            ),
            const SizedBox(height: 10),
            TextField(controller: remarks, maxLines: 3, decoration: const InputDecoration(labelText: 'Remarks')),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Complete QC'),
        ),
      ],
    );
  }
}
