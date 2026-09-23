import 'package:flutter/material.dart';
import '../common_widgets.dart';
import '../../services/return_service.dart';
import '../../services/order_service.dart';

class ClientReturnsScreen extends StatefulWidget {
  const ClientReturnsScreen({super.key});
  @override
  State<ClientReturnsScreen> createState() => _ClientReturnsScreenState();
}

class _ClientReturnsScreenState extends State<ClientReturnsScreen> {
  final api = ReturnService.instance;
  final orderApi = OrderService.instance;
  List<Map<String, dynamic>> returns = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> invoices = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([api.list(), api.sourceOrders(), api.sourceInvoices()]);
      if (mounted) {
        setState(() {
          returns = r[0];
          orders = r[1];
          invoices = r[2];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> requestReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ClientReturnDialog(api: api, orderApi: orderApi, orders: orders, invoices: invoices),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return request submitted.')));
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Returns',
      subtitle: 'Request and track material returns for your account.',
      actions: [
        OutlinedButton.icon(onPressed: load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: requestReturn, icon: const Icon(Icons.assignment_return_outlined), label: const Text('Request Return')),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  OutlinedButton(onPressed: load, child: const Text('Retry')),
                ]))
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SummaryCards(items: [
                    ['Requested / Gate In', returns.where((x) => ['requested','gate_in_pending'].contains(x['status'])).length.toString()],
                    ['QC Pending', returns.where((x) => x['status'] == 'qc_pending').length.toString()],
                    ['Completed', returns.where((x) => x['status'] == 'completed').length.toString()],
                    ['Rejected', returns.where((x) => x['status'] == 'rejected').length.toString()],
                  ]),
                  const SizedBox(height: 18),
                  DataTableCard(
                    headers: const ['Return ID','Order','Invoice','Qty','Reason','Status'],
                    rows: returns.map((x) => [
                      (x['return_no'] ?? '-').toString(),
                      (x['order_no'] ?? '-').toString(),
                      (x['invoice_no'] ?? '-').toString(),
                      (x['total_returned_qty'] ?? 0).toString(),
                      (x['reason'] ?? '-').toString(),
                      (x['status'] ?? '-').toString(),
                    ]).toList(),
                    statusColumns: const [5],
                  ),
                ]),
    );
  }
}

class _ClientReturnDialog extends StatefulWidget {
  final ReturnService api;
  final OrderService orderApi;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> invoices;

  const _ClientReturnDialog({
    required this.api,
    required this.orderApi,
    required this.orders,
    required this.invoices,
  });

  @override
  State<_ClientReturnDialog> createState() => _ClientReturnDialogState();
}

class _ClientReturnDialogState extends State<_ClientReturnDialog> {
  String type = 'Order';
  Map<String, dynamic>? source;
  Map<String, dynamic>? order;
  List<Map<String, dynamic>> items = [];
  final reason = TextEditingController();
  final quantities = <String, TextEditingController>{};
  bool loading = false;
  bool saving = false;

  List<Map<String, dynamic>> get sources => type == 'Order' ? widget.orders : widget.invoices;

  @override
  void dispose() {
    reason.dispose();
    for (final c in quantities.values) c.dispose();
    super.dispose();
  }

  Future<void> selectSource(Map<String, dynamic>? value) async {
    if (value == null) return;
    for (final c in quantities.values) c.dispose();
    quantities.clear();
    setState(() { source = value; order = null; items = []; loading = true; });
    try {
      final id = type == 'Order' ? value['id'].toString() : value['order_id'].toString();
      final d = await widget.orderApi.detail(id);
      final loaded = (d['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((x) => (double.tryParse(x['dispatched_qty']?.toString() ?? '0') ?? 0) > 0)
          .toList();
      for (final x in loaded) {
        quantities[x['id'].toString()] = TextEditingController(text: '0');
      }
      if (mounted) setState(() { order = d; items = loaded; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    if (order == null || source == null || reason.text.trim().isEmpty) return;
    final selected = <Map<String, dynamic>>[];
    for (final x in items) {
      final q = double.tryParse(quantities[x['id'].toString()]!.text) ?? 0;
      if (q > 0) selected.add({'orderItemId': x['id'].toString(), 'returnedQty': q});
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter return quantity for at least one item.')));
      return;
    }
    try {
      setState(() => saving = true);
      await widget.api.create(
        orderId: type == 'Order' ? order!['id'].toString() : null,
        invoiceId: type == 'Invoice' ? source!['invoice_id'].toString() : null,
        warehouseId: order!['warehouse_id'].toString(),
        reason: reason.text.trim(),
        items: selected,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Material Return'),
      content: SizedBox(
        width: 850,
        height: 600,
        child: Column(children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Return Against', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Order', child: Text('Original Order')),
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() { type = v; source = null; order = null; items = []; });
              },
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: DropdownButtonFormField<Map<String, dynamic>>(
              value: source,
              decoration: InputDecoration(labelText: 'Select ' + type, border: const OutlineInputBorder()),
              items: sources.map((x) {
                final label = type == 'Order'
                    ? x['order_no'].toString() + ' • ' + x['client_name'].toString()
                    : x['invoice_no'].toString() + ' • Order ' + x['order_no'].toString();
                return DropdownMenuItem(value: x, child: Text(label, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: selectSource,
            )),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('Select an order or invoice to load dispatched items.'))
                    : HorizontalTableScroller(child: DataTable(
                        columns: const [
                          DataColumn(label: Text('SKU')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Dispatched')),
                          DataColumn(label: Text('Return Qty')),
                        ],
                        rows: items.map((x) => DataRow(cells: [
                          DataCell(Text(x['sku'].toString())),
                          DataCell(Text(x['product_name'].toString())),
                          DataCell(Text(x['dispatched_qty'].toString())),
                          DataCell(SizedBox(width: 120, child: TextField(
                            controller: quantities[x['id'].toString()],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          ))),
                        ])).toList(),
                      )),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reason,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Return Reason *', border: OutlineInputBorder()),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: saving ? null : submit, child: const Text('Submit Request')),
      ],
    );
  }
}
