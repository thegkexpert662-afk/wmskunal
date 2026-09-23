import 'package:flutter/material.dart';
import '../common_widgets.dart';
import '../../services/return_service.dart';
import '../../services/order_service.dart';
import '../../services/warehouse_service.dart';

class AdminReturnsScreen extends StatefulWidget {
  const AdminReturnsScreen({super.key});
  @override
  State<AdminReturnsScreen> createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends State<AdminReturnsScreen> {
  final api = ReturnService.instance;
  final orderApi = OrderService.instance;
  List<Map<String, dynamic>> returns = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> invoices = [];
  bool loading = true;
  String? error;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([
        api.list(status: filter),
        api.sourceOrders(),
        api.sourceInvoices(),
      ]);
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

  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> createReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateReturnDialog(
        api: api,
        orderApi: orderApi,
        orders: orders,
        invoices: invoices,
      ),
    );
    if (ok == true) {
      msg('Return request created.');
      await load();
    }
  }

  Future<void> openReturn(Map<String, dynamic> row) async {
    try {
      final detail = await api.detail(row['id'].toString());
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _ReturnDetailDialog(detail: detail, api: api),
      );
      await load();
    } catch (e) {
      msg(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Returns',
      subtitle: 'Return request → Gate In → QC → inventory adjustment → completion.',
      actions: [
        OutlinedButton.icon(onPressed: load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: createReturn, icon: const Icon(Icons.assignment_return_outlined), label: const Text('Create Return')),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  OutlinedButton(onPressed: load, child: const Text('Retry')),
                ]))
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _stats(),
                  const SizedBox(height: 14),
                  _filters(),
                  const SizedBox(height: 14),
                  _table(),
                ]),
    );
  }

  Widget _stats() {
    int count(String s) => returns.where((x) => x['status'] == s).length;
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _stat('Requested / Gate In', count('requested') + count('gate_in_pending'), Icons.login_outlined),
      _stat('QC Pending', count('qc_pending'), Icons.fact_check_outlined),
      _stat('Completed', count('completed'), Icons.check_circle_outline),
      _stat('Rejected', count('rejected'), Icons.block_outlined),
      _stat('Cancelled', count('cancelled'), Icons.cancel_outlined),
    ]);
  }

  Widget _stat(String title, int value, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1))),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1769D5)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _filters() {
    const values = ['All','requested','gate_in_pending','qc_pending','completed','rejected','cancelled'];
    return Wrap(spacing: 8, runSpacing: 8, children: values.map((v) => ChoiceChip(
      label: Text(v.replaceAll('_', ' ').toUpperCase()),
      selected: filter == v,
      onSelected: (_) async { setState(() => filter = v); await load(); },
    )).toList());
  }

  Widget _table() {
    if (returns.isEmpty) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No return records found.')));
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1E8F1))),
      child: HorizontalTableScroller(child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
        columns: const [
          DataColumn(label: Text('Return No.')),
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Invoice')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Warehouse')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: returns.map((x) => DataRow(cells: [
          DataCell(Text((x['return_no'] ?? '-').toString())),
          DataCell(Text((x['order_no'] ?? '-').toString())),
          DataCell(Text((x['invoice_no'] ?? '-').toString())),
          DataCell(Text((x['client_name'] ?? '-').toString())),
          DataCell(Text((x['warehouse_name'] ?? '-').toString())),
          DataCell(Text((x['total_returned_qty'] ?? 0).toString())),
          DataCell(SizedBox(width: 180, child: Text((x['reason'] ?? '-').toString(), overflow: TextOverflow.ellipsis))),
          DataCell(_chip((x['status'] ?? '-').toString())),
          DataCell(IconButton(tooltip: 'Open Return', onPressed: () => openReturn(x), icon: const Icon(Icons.visibility_outlined))),
        ])).toList(),
      )),
    );
  }

  Widget _chip(String value) => Chip(
    label: Text(value.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
    visualDensity: VisualDensity.compact,
  );
}

class _CreateReturnDialog extends StatefulWidget {
  final ReturnService api;
  final OrderService orderApi;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> invoices;

  const _CreateReturnDialog({required this.api, required this.orderApi, required this.orders, required this.invoices});

  @override
  State<_CreateReturnDialog> createState() => _CreateReturnDialogState();
}

class _CreateReturnDialogState extends State<_CreateReturnDialog> {
  String sourceType = 'Order';
  Map<String, dynamic>? source;
  Map<String, dynamic>? order;
  List<Map<String, dynamic>> items = [];
  final reason = TextEditingController();
  final quantities = <String, TextEditingController>{};
  bool loading = false;
  bool saving = false;

  List<Map<String, dynamic>> get sources => sourceType == 'Order' ? widget.orders : widget.invoices;

  @override
  void dispose() {
    reason.dispose();
    for (final c in quantities.values) c.dispose();
    super.dispose();
  }

  Future<void> chooseSource(Map<String, dynamic>? value) async {
    if (value == null) return;
    setState(() { source = value; loading = true; order = null; items = []; });
    for (final c in quantities.values) c.dispose();
    quantities.clear();
    try {
      final orderId = sourceType == 'Order' ? value['id'].toString() : value['order_id'].toString();
      final detail = await widget.orderApi.detail(orderId);
      final loaded = (detail['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((x) => (double.tryParse(x['dispatched_qty']?.toString() ?? '0') ?? 0) > 0)
          .toList();
      for (final x in loaded) quantities[x['id'].toString()] = TextEditingController(text: '0');
      if (mounted) setState(() { order = detail; items = loaded; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (order == null || source == null || reason.text.trim().isEmpty) return;
    final selected = <Map<String, dynamic>>[];
    for (final x in items) {
      final value = double.tryParse(quantities[x['id'].toString()]!.text) ?? 0;
      if (value <= 0) continue;
      selected.add({'orderItemId': x['id'].toString(), 'returnedQty': value});
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter return quantity for at least one item.')));
      return;
    }
    try {
      setState(() => saving = true);
      await widget.api.create(
        orderId: sourceType == 'Order' ? order!['id'].toString() : null,
        invoiceId: sourceType == 'Invoice' ? source!['invoice_id'].toString() : null,
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
      title: const Text('Create Return Request'),
      content: SizedBox(
        width: 900,
        height: 650,
        child: Column(children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: sourceType,
              decoration: const InputDecoration(labelText: 'Return Against', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Order', child: Text('Original Order')),
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() { sourceType = v; source = null; order = null; items = []; });
              },
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: DropdownButtonFormField<Map<String, dynamic>>(
              value: source,
              decoration: InputDecoration(labelText: 'Select ' + sourceType, border: const OutlineInputBorder()),
              items: sources.map((x) {
                final label = sourceType == 'Order'
                    ? (x['order_no'].toString() + ' • ' + x['client_name'].toString() + ' • ' + x['warehouse_code'].toString())
                    : (x['invoice_no'].toString() + ' • Order ' + x['order_no'].toString() + ' • ' + x['client_name'].toString());
                return DropdownMenuItem(value: x, child: Text(label, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: chooseSource,
            )),
          ]),
          const SizedBox(height: 12),
          if (order != null)
            Align(alignment: Alignment.centerLeft, child: Text(
              'Order: ' + order!['order_no'].toString() + ' • Client: ' + order!['client_name'].toString() + ' • Warehouse: ' + order!['warehouse_code'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            )),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('Select an order/invoice to load dispatched items.'))
                    : HorizontalTableScroller(child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
                        columns: const [
                          DataColumn(label: Text('SKU')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Dispatched')),
                          DataColumn(label: Text('Return Qty')),
                          DataColumn(label: Text('UOM')),
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
                          DataCell(Text((x['uom'] ?? '-').toString())),
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
        FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.add), label: const Text('Create Return')),
      ],
    );
  }
}

class _ReturnDetailDialog extends StatefulWidget {
  final Map<String, dynamic> detail;
  final ReturnService api;
  const _ReturnDetailDialog({required this.detail, required this.api});

  @override
  State<_ReturnDetailDialog> createState() => _ReturnDetailDialogState();
}

class _ReturnDetailDialogState extends State<_ReturnDetailDialog> {
  bool busy = false;
  final accepted = <String, TextEditingController>{};
  final damaged = <String, TextEditingController>{};
  final rejected = <String, TextEditingController>{};
  final locations = <String, String?>{};
  List<Map<String, dynamic>> warehouseLocations = [];
  bool locationLoading = false;

  String value(dynamic x) {
    final s = x?.toString().trim() ?? '';
    return s.isEmpty || s == 'null' ? '-' : s;
  }

  @override
  void dispose() {
    for (final map in [accepted, damaged, rejected]) {
      for (final c in map.values) c.dispose();
    }
    super.dispose();
  }

  void init(List<Map<String, dynamic>> items) {
    for (final x in items) {
      final id = x['id'].toString();
      accepted.putIfAbsent(id, () => TextEditingController(text: '0'));
      damaged.putIfAbsent(id, () => TextEditingController(text: '0'));
      rejected.putIfAbsent(id, () => TextEditingController(text: '0'));
    }
  }

  Future<void> loadLocations() async {
    if (locationLoading || warehouseLocations.isNotEmpty) return;
    setState(() => locationLoading = true);
    try {
      final id = widget.detail['warehouse_id']?.toString();
      if (id != null && id.isNotEmpty) {
        final rows = await WarehouseService.instance.getLocations(id);
        if (mounted) setState(() => warehouseLocations = rows.where((x) => x['is_active'] == true).toList());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => locationLoading = false);
    }
  }

  Future<void> gateIn() async {
    try {
      setState(() => busy = true);
      await widget.api.gateIn(widget.detail['id'].toString());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> completeQc() async {
    final items = (widget.detail['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final payload = items.map((x) {
      final id = x['id'].toString();
      return {
        'returnItemId': id,
        'acceptedQty': double.tryParse(accepted[id]?.text ?? '0') ?? 0,
        'damagedQty': double.tryParse(damaged[id]?.text ?? '0') ?? 0,
        'rejectedQty': double.tryParse(rejected[id]?.text ?? '0') ?? 0,
        'locationId': locations[id],
      };
    }).toList();
    try {
      setState(() => busy = true);
      await widget.api.qc(widget.detail['id'].toString(), payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancelReturn() async {
    try {
      setState(() => busy = true);
      await widget.api.cancel(widget.detail['id'].toString());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.detail['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    init(items);
    final status = value(widget.detail['status']).toLowerCase();

    return AlertDialog(
      title: Text(value(widget.detail['return_no']) + ' • ' + value(widget.detail['order_no'])),
      content: SizedBox(
        width: 1100,
        height: 680,
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(widget.detail),
          const SizedBox(height: 14),
          const Text('Returned Items & QC', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          HorizontalTableScroller(child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
            columns: const [
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Returned')),
              DataColumn(label: Text('Accepted')),
              DataColumn(label: Text('Damaged')),
              DataColumn(label: Text('Rejected')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('QC')),
            ],
            rows: items.map((x) {
              final id = x['id'].toString();
              return DataRow(cells: [
                DataCell(Text(value(x['sku']))),
                DataCell(Text(value(x['product_name']))),
                DataCell(Text(value(x['returned_qty']))),
                DataCell(SizedBox(width: 90, child: TextField(controller: accepted[id], enabled: status == 'qc_pending', keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
                DataCell(SizedBox(width: 90, child: TextField(controller: damaged[id], enabled: status == 'QC_PENDING', keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
                DataCell(SizedBox(width: 90, child: TextField(controller: rejected[id], enabled: status == 'QC_PENDING', keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())))),
                DataCell(SizedBox(width: 190, child: DropdownButton<String>(
                  isExpanded: true,
                  value: locations[id],
                  hint: const Text('Location'),
                  items: warehouseLocations.map((loc) => DropdownMenuItem(value: loc['id'].toString(), child: Text(loc['code'].toString()))).toList(),
                  onChanged: status == 'qc_pending' ? (v) => setState(() => locations[id] = v) : null,
                ))),
                DataCell(_chip(value(x['qc_result']))),
              ]);
            }).toList(),
          )),
          const SizedBox(height: 10),
          if (status == 'qc_pending')
            OutlinedButton.icon(onPressed: locationLoading ? null : loadLocations, icon: const Icon(Icons.location_on_outlined), label: Text(locationLoading ? 'Loading...' : 'Load Warehouse Locations')),
        ])),
      ),
      actions: [
        if (status == 'gate_in_pending')
          FilledButton.icon(onPressed: busy ? null : gateIn, icon: const Icon(Icons.login_outlined), label: const Text('Confirm Gate In')),
        if (status == 'QC_PENDING')
          FilledButton.icon(onPressed: busy ? null : completeQc, icon: const Icon(Icons.fact_check_outlined), label: const Text('Complete QC')),
        if (['requested','gate_in_pending','qc_pending'].contains(status))
          TextButton(onPressed: busy ? null : cancelReturn, child: const Text('Cancel Return')),
        TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _header(Map<String, dynamic> d) {
    Widget row(String label, dynamic x) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(value(x), style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF7FAFD), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E7EF))),
      child: Column(children: [
        row('Client', d['client_name']),
        row('Order', d['order_no']),
        row('Invoice', d['invoice_no']),
        row('Warehouse', d['warehouse_name']),
        row('Reason', d['reason']),
        row('Status', d['status']),
      ]),
    );
  }

  Widget _chip(String s) => Chip(
    label: Text(s.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800)),
    visualDensity: VisualDensity.compact,
  );
}
