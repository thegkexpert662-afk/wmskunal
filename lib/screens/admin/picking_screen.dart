import 'package:flutter/material.dart';
import '../../services/picking_service.dart';
import '../common_widgets.dart';

class AdminPickingScreen extends StatefulWidget {
  const AdminPickingScreen({super.key});

  @override
  State<AdminPickingScreen> createState() => _AdminPickingScreenState();
}

class _AdminPickingScreenState extends State<AdminPickingScreen> {
  final api = PickingService.instance;
  List<Map<String, dynamic>> tasks = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.tasks();
      if (mounted) setState(() => tasks = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void msg(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> createTask() async {
    try {
      final orders = await api.pending();
      if (!mounted) return;
      if (orders.isEmpty) {
        msg('No allocated/picking orders available.');
        return;
      }

      final id = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Order for Picking'),
          content: SizedBox(
            width: 700,
            height: 430,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                    '${order['order_no'] ?? '-'} • ${order['client_name'] ?? '-'}',
                  ),
                  subtitle: Text(
                    '${order['warehouse_name'] ?? '-'} • '
                    'Items ${order['item_count'] ?? 0} • '
                    'Remaining ${order['remaining_qty'] ?? 0}',
                  ),
                  onTap: () => Navigator.pop(context, order['id'].toString()),
                );
              },
            ),
          ),
        ),
      );

      if (id == null) return;
      await api.createTask(id);
      msg('Picking task created.');
      await load();
    } catch (e) {
      msg(e.toString());
    }
  }

  Future<void> openTask(Map<String, dynamic> task) async {
    try {
      final detail = await api.detail(task['id'].toString());
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _PickingListDialog(detail: detail, api: api),
      );
      await load();
    } catch (e) {
      msg(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Picking',
      subtitle: 'Location-wise picking list with customer, shipment and vehicle information.',
      actions: [
        OutlinedButton.icon(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: createTask,
          icon: const Icon(Icons.add_task),
          label: const Text('Create Pick Task'),
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
              : tasks.isEmpty
                  ? const Center(child: Text('No picking tasks.'))
                  : HorizontalTableScroller(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Pick Task')),
                          DataColumn(label: Text('Order')),
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Warehouse')),
                          DataColumn(label: Text('Picker')),
                          DataColumn(label: Text('Picked')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: tasks.map((task) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                task['id'].toString().substring(0, 8).toUpperCase(),
                              )),
                              DataCell(Text((task['order_no'] ?? '-').toString())),
                              DataCell(Text((task['client_name'] ?? '-').toString())),
                              DataCell(Text((task['warehouse_name'] ?? '-').toString())),
                              DataCell(Text((task['picker_name'] ?? '-').toString())),
                              DataCell(Text((task['picked_qty'] ?? 0).toString())),
                              DataCell(_statusChip((task['status'] ?? '-').toString())),
                              DataCell(
                                IconButton(
                                  tooltip: 'Open Picking List',
                                  icon: const Icon(Icons.visibility_outlined),
                                  onPressed: () => openTask(task),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
    );
  }

  Widget _statusChip(String status) {
    final active = status == 'in_progress';
    final completed = status == 'completed';
    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      avatar: Icon(
        completed
            ? Icons.check_circle
            : active
                ? Icons.timelapse
                : Icons.pending_actions,
        size: 16,
      ),
    );
  }
}

class _PickingListDialog extends StatefulWidget {
  final Map<String, dynamic> detail;
  final PickingService api;

  const _PickingListDialog({
    required this.detail,
    required this.api,
  });

  @override
  State<_PickingListDialog> createState() => _PickingListDialogState();
}

class _PickingListDialogState extends State<_PickingListDialog> {
  bool busy = false;

  double number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

  String text(dynamic value, [String fallback = '-']) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty || valueText == 'null' ? fallback : valueText;
  }

  String date(dynamic value) {
    if (value == null) return '-';
    final raw = value.toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  void msg(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> pick(Map<String, dynamic> item) async {
    final plan = (widget.detail['pickPlan'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['orderItemId'] == item['order_item_id'])
        .toList();

    if (plan.isEmpty) {
      msg('No available stock locations for this item.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PickDialog(item: item, plan: plan),
    );
    if (result == null) return;

    try {
      setState(() => busy = true);
      await widget.api.pick(
        widget.detail['task']['id'].toString(),
        orderItemId: item['order_item_id'].toString(),
        locationId: result['locationId'].toString(),
        quantity: result['quantity'] as double,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      msg(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> complete() async {
    try {
      setState(() => busy = true);
      await widget.api.complete(widget.detail['task']['id'].toString());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      msg(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _infoCard(
    String title,
    IconData icon,
    Color accent,
    List<Widget> children,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withOpacity(.22)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 19),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: text(value)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = Map<String, dynamic>.from(widget.detail['task'] as Map);
    final items = (widget.detail['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final totalOrder = items.fold<double>(
      0,
      (sum, item) => sum + number(item['ordered_qty']),
    );
    final totalPicked = items.fold<double>(
      0,
      (sum, item) => sum + number(item['picked_qty']),
    );
    final totalRemaining = items.fold<double>(
      0,
      (sum, item) => sum + number(item['remaining_qty']),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 1280,
        height: MediaQuery.sizeOf(context).height * .92,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F8FC),
                border: Border(bottom: BorderSide(color: Color(0xFFD8E0EA))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add_check_rounded, size: 32, color: Color(0xFF1769D5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PICKING LIST',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'PL-${task['id'].toString().substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${text(task['order_no'])} • ${text(task['warehouse_name'])}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      text(task['status']).replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _headerBlock(task),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _infoCard(
                        'CLIENT',
                        Icons.groups_outlined,
                        const Color(0xFF1769D5),
                        [
                          Text(
                            text(task['client_name']),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          _kv('Code', task['client_code']),
                          _kv('GST', task['client_gstin']),
                        ],
                      ),
                      _infoCard(
                        'SOLD BY',
                        Icons.business_outlined,
                        Colors.green.shade700,
                        [
                          Text(text(task['sold_by_name']), style: const TextStyle(fontWeight: FontWeight.w900)),
                          _kv('Address', task['sold_by_address']),
                          _kv('GST', task['sold_by_gstin']),
                        ],
                      ),
                      _infoCard(
                        'SOLD TO',
                        Icons.storefront_outlined,
                        Colors.red.shade700,
                        [
                          Text(text(task['sold_to_name']), style: const TextStyle(fontWeight: FontWeight.w900)),
                          _kv('Address', task['sold_to_address']),
                          _kv('GST', task['sold_to_gstin']),
                        ],
                      ),
                      _infoCard(
                        'SHIP TO',
                        Icons.local_shipping_outlined,
                        Colors.deepPurple.shade700,
                        [
                          Text(text(task['ship_to_name']), style: const TextStyle(fontWeight: FontWeight.w900)),
                          _kv('Address', task['ship_to_address']),
                          _kv('GST', task['ship_to_gstin']),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Picking Items • Location Wise',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  _itemsTable(items),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _summaryCard('Total SKUs', items.length.toString(), Icons.category_outlined),
                      _summaryCard('Order Qty', totalOrder.toStringAsFixed(2), Icons.inventory_2_outlined),
                      _summaryCard('Picked Qty', totalPicked.toStringAsFixed(2), Icons.check_circle_outline),
                      _summaryCard('Balance', totalRemaining.toStringAsFixed(2), Icons.pending_actions),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE1E7EF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_outlined, color: Color(0xFF1769D5)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(text(task['remarks'], 'No remarks added.'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFD8E0EA))),
              ),
              child: Row(
                children: [
                  Text(
                    'Picker: ${text(task['picker_name'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: busy || totalRemaining > 0 ? null : complete,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete Picking'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBlock(Map<String, dynamic> task) {
    Widget cell(String label, dynamic value) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 12),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: text(value)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8E0EA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(children: [
            cell('Warehouse / Plant', task['warehouse_name']),
            cell('Picking Date', date(task['created_at'])),
            cell('Order No.', task['order_no']),
            cell('Order Date', date(task['required_date'])),
          ]),
          const Divider(),
          Row(children: [
            cell('Shipment No.', task['shipment_no']),
            cell('Shipment Date', date(task['shipment_date'])),
            cell('Delivery No.', task['delivery_no']),
            cell('Delivery Date', date(task['delivery_date'])),
          ]),
          const Divider(),
          Row(children: [
            cell('Truck Type', task['truck_type']),
            cell('Transporter', task['transporter_name']),
            cell('Vehicle No.', task['vehicle_no']),
            cell('Driver Name', task['driver_name']),
            cell('Driver Mobile', task['driver_mobile']),
          ]),
        ],
      ),
    );
  }

  Widget _itemsTable(List<Map<String, dynamic>> items) {
    return HorizontalTableScroller(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FB)),
        columns: const [
          DataColumn(label: Text('Sr')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Available')),
          DataColumn(label: Text('Reserved')),
          DataColumn(label: Text('Order Qty')),
          DataColumn(label: Text('Picked')),
          DataColumn(label: Text('Balance')),
          DataColumn(label: Text('UOM')),
          DataColumn(label: Text('Action')),
        ],
        rows: items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final remaining = number(item['remaining_qty']);
          final picked = number(item['picked_qty']);
          final ordered = number(item['ordered_qty']);

          final plan = (widget.detail['pickPlan'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => e['orderItemId'] == item['order_item_id'])
              .toList();

          final available = plan.fold<double>(
            0,
            (sum, p) => sum + number(p['availableQuantity']),
          );

          return DataRow(
            cells: [
              DataCell(Text(index.toString())),
              DataCell(Text(text(item['sku']))),
              DataCell(Text(text(item['product_name']))),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    plan.map((e) => text(e['locationCode'])).join(', '),
                  ),
                ),
              ),
              DataCell(Text(available.toStringAsFixed(2))),
              DataCell(const Text('-')),
              DataCell(Text(ordered.toStringAsFixed(2))),
              DataCell(Text(picked.toStringAsFixed(2))),
              DataCell(Text(remaining.toStringAsFixed(2))),
              DataCell(Text(text(item['uom']))),
              DataCell(
                remaining > 0
                    ? FilledButton(
                        onPressed: busy ? null : () => pick(item),
                        child: const Text('Pick'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1769D5)),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> plan;

  const _PickDialog({
    required this.item,
    required this.plan,
  });

  @override
  State<_PickDialog> createState() => _PickDialogState();
}

class _PickDialogState extends State<_PickDialog> {
  late Map<String, dynamic> selected;
  late TextEditingController qty;

  @override
  void initState() {
    super.initState();
    selected = widget.plan.first;
    qty = TextEditingController(
      text: selected['suggestedPickQuantity'].toString(),
    );
  }

  @override
  void dispose() {
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pick ${widget.item['product_name'] ?? ''}'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selected,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              items: widget.plan.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p['locationCode']} • Available ${p['availableQuantity']} • '
                    'Suggested ${p['suggestedPickQuantity']}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selected = value;
                    qty.text = value['suggestedPickQuantity'].toString();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Pick Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(qty.text) ?? 0;
            if (value <= 0) return;
            Navigator.pop(context, {
              'locationId': selected['locationId'],
              'quantity': value,
            });
          },
          child: const Text('Confirm Pick'),
        ),
      ],
    );
  }
}
