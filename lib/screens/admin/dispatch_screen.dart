import 'package:flutter/material.dart';
import '../common_widgets.dart';
import '../../services/dispatch_service.dart';

class AdminDispatchScreen extends StatefulWidget {
  const AdminDispatchScreen({super.key});

  @override
  State<AdminDispatchScreen> createState() => _AdminDispatchScreenState();
}

class _AdminDispatchScreenState extends State<AdminDispatchScreen> {
  final api = DispatchService.instance;
  List<Map<String, dynamic>> dispatches = [];
  List<Map<String, dynamic>> pending = [];
  bool loading = true;
  String? error;
  String status = 'All';
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        api.list(status: status == 'All' ? null : status),
        api.pending(),
      ]);
      if (mounted) {
        setState(() {
          dispatches = results[0];
          pending = results[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return dispatches;
    return dispatches.where((x) {
      return [
        x['dispatch_no'],
        x['order_no'],
        x['client_name'],
        x['warehouse_name'],
        x['vehicle_no'],
        x['lr_no'],
      ].any((v) => (v ?? '').toString().toLowerCase().contains(q));
    }).toList();
  }

  void msg(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> createDispatch() async {
    if (pending.isEmpty) {
      msg('No packed orders are ready for dispatch.');
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PendingDispatchDialog(orders: pending),
    );
    if (selected == null) return;

    final vehicle = TextEditingController(text: selected['vehicle_no']?.toString() ?? '');
    final transporter = TextEditingController(text: selected['transporter_name']?.toString() ?? '');
    final driver = TextEditingController(text: selected['driver_name']?.toString() ?? '');
    final mobile = TextEditingController(text: selected['driver_mobile']?.toString() ?? '');
    final lr = TextEditingController();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Create Dispatch • ${selected['order_no'] ?? '-'}'),
          content: SizedBox(
            width: 650,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(vehicle, 'Vehicle No.'),
                const SizedBox(height: 10),
                _field(transporter, 'Transporter'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(driver, 'Driver Name')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(mobile, 'Driver Mobile')),
                ]),
                const SizedBox(height: 10),
                _field(lr, 'LR / AWB No.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create Dispatch'),
            ),
          ],
        ),
      );
      if (ok != true) return;

      final created = await api.create(
        orderId: selected['order_id'].toString(),
        vehicleNo: vehicle.text.trim().isEmpty ? null : vehicle.text.trim(),
        transporterName: transporter.text.trim().isEmpty ? null : transporter.text.trim(),
        driverName: driver.text.trim().isEmpty ? null : driver.text.trim(),
        driverMobile: mobile.text.trim().isEmpty ? null : mobile.text.trim(),
        lrNo: lr.text.trim().isEmpty ? null : lr.text.trim(),
      );
      final invoice = created['_invoice'];
      msg('Dispatch created. Invoice ' + (invoice is Map ? (invoice['invoice_no'] ?? '-').toString() : '-') + ' created and ready for gate-out.');
      await load();
    } catch (e) {
      msg(e.toString());
    } finally {
      vehicle.dispose();
      transporter.dispose();
      driver.dispose();
      mobile.dispose();
      lr.dispose();
    }
  }

  Future<void> open(Map<String, dynamic> row) async {
    try {
      final detail = await api.detail(row['id'].toString());
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _DispatchDetailDialog(detail: detail, api: api),
      );
      await load();
    } catch (e) {
      msg(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Outward / Dispatch',
      subtitle: 'Packed orders → dispatch creation → gate-out → transit → delivery.',
      actions: [
        OutlinedButton.icon(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: createDispatch,
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Create Dispatch'),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      OutlinedButton(onPressed: load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stats(),
                    const SizedBox(height: 14),
                    _table(),
                  ],
                ),
    );
  }

  Widget _stats() {
    int count(String s) => dispatches.where((x) => x['status'] == s).length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _stat('Ready', count('ready'), Icons.inventory_2_outlined),
        _stat('Dispatched', count('dispatched'), Icons.output_outlined),
        _stat('In Transit', count('in_transit'), Icons.route_outlined),
        _stat('Delivered', count('delivered'), Icons.check_circle_outline),
        _stat('Pending Packed Orders', pending.length, Icons.pending_actions),
      ],
    );
  }

  Widget _stat(String title, int value, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1769D5)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(11),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 320,
                  height: 40,
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(
                      hintText: 'Search dispatch, order, client, vehicle...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 170,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      'All',
                      'ready',
                      'dispatched',
                      'in_transit',
                      'delivered',
                      'cancelled',
                    ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => status = v);
                      await load();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(35),
                  child: Text('No dispatch records found.'),
                )
              : HorizontalTableScroller(
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
                    columns: const [
                      DataColumn(label: Text('Dispatch')),
                      DataColumn(label: Text('Order')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Warehouse')),
                      DataColumn(label: Text('Vehicle')),
                      DataColumn(label: Text('LR / AWB')),
                      DataColumn(label: Text('Packages')),
                      DataColumn(label: Text('Weight KG')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filtered.map((x) {
                      return DataRow(cells: [
                        DataCell(Text((x['dispatch_no'] ?? '-').toString())),
                        DataCell(Text((x['order_no'] ?? '-').toString())),
                        DataCell(Text((x['client_name'] ?? '-').toString())),
                        DataCell(Text((x['warehouse_name'] ?? '-').toString())),
                        DataCell(Text((x['vehicle_no'] ?? '-').toString())),
                        DataCell(Text((x['lr_no'] ?? '-').toString())),
                        DataCell(Text((x['total_packages'] ?? 0).toString())),
                        DataCell(Text((x['total_weight'] ?? 0).toString())),
                        DataCell(_status((x['status'] ?? '-').toString())),
                        DataCell(
                          IconButton(
                            tooltip: 'Open Dispatch',
                            onPressed: () => open(x),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${filtered.length} dispatch record(s)',
                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String value) {
    return Chip(
      label: Text(
        value.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PendingDispatchDialog extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const _PendingDispatchDialog({required this.orders});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Packed Orders Ready for Dispatch'),
      content: SizedBox(
        width: 800,
        height: 420,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final x = orders[index];
            return ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text('${x['order_no'] ?? '-'} • ${x['client_name'] ?? '-'}'),
              subtitle: Text(
                '${x['warehouse_name'] ?? '-'} • '
                'Packages ${x['total_packages'] ?? 0} • '
                'Weight ${x['total_weight'] ?? 0} KG',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, x),
            );
          },
        ),
      ),
    );
  }
}

class _DispatchDetailDialog extends StatefulWidget {
  final Map<String, dynamic> detail;
  final DispatchService api;

  const _DispatchDetailDialog({
    required this.detail,
    required this.api,
  });

  @override
  State<_DispatchDetailDialog> createState() => _DispatchDetailDialogState();
}

class _DispatchDetailDialogState extends State<_DispatchDetailDialog> {
  bool busy = false;

  String text(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty || s == 'null' ? '-' : s;
  }

  Future<void> action(Future<Map<String, dynamic>> Function() call) async {
    try {
      setState(() => busy = true);
      await call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final items = (d['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final status = text(d['status']);

    return AlertDialog(
      title: Text('${text(d['dispatch_no'])} • ${text(d['order_no'])}'),
      content: SizedBox(
        width: 900,
        height: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(d),
              const SizedBox(height: 14),
              const Text('Dispatch Items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              HorizontalTableScroller(
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
                  columns: const [
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('UOM')),
                  ],
                  rows: items.map((x) => DataRow(cells: [
                    DataCell(Text(text(x['sku']))),
                    DataCell(Text(text(x['product_name']))),
                    DataCell(Text(text(x['quantity']))),
                    DataCell(Text(text(x['uom']))),
                  ])).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Close')),
        if (status == 'ready')
          FilledButton.icon(
            onPressed: busy ? null : () => action(() => widget.api.gateOut(d['id'].toString())),
            icon: const Icon(Icons.output_outlined),
            label: const Text('Gate Out / Dispatch'),
          ),
        if (status == 'dispatched')
          FilledButton.tonal(
            onPressed: busy ? null : () => action(() => widget.api.updateStatus(d['id'].toString(), 'in_transit')),
            child: const Text('Mark In Transit'),
          ),
        if (status == 'in_transit')
          FilledButton(
            onPressed: busy ? null : () => action(() => widget.api.updateStatus(d['id'].toString(), 'delivered')),
            child: const Text('Mark Delivered'),
          ),
      ],
    );
  }

  Widget _header(Map<String, dynamic> d) {
    Widget row(String label, dynamic value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(text(value), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E7EF)),
      ),
      child: Column(
        children: [
          row('Client', d['client_name']),
          row('Warehouse', d['warehouse_name']),
          row('Vehicle No.', d['vehicle_no']),
          row('Transporter', d['transporter_name']),
          row('Driver', d['driver_name']),
          row('Driver Mobile', d['driver_mobile']),
          row('LR / AWB', d['lr_no']),
          row('Packages', d['total_packages']),
          row('Total Weight KG', d['total_weight']),
          row('Ship To', d['ship_to_name']),
          row('Ship To Address', d['ship_to_address']),
        ],
      ),
    );
  }
}
