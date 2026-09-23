import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../common_widgets.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final api = InventoryService.instance;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> txns = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = await api.getInventory();
      txns = await api.transactions();
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Inventory / Stock',
      subtitle: 'Live warehouse stock, available quantity and stock ledger.',
      actions: [
        OutlinedButton.icon(
          onPressed: loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _error()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stats(),
                    const SizedBox(height: 16),
                    _currentStock(),
                    const SizedBox(height: 16),
                    _stockLedger(),
                  ],
                ),
    );
  }

  Widget _currentStock() {
    final content = items.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('No inventory found.')),
          )
        : HorizontalTableScroller(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Reserved')),
                DataColumn(label: Text('Available')),
                DataColumn(label: Text('Damaged')),
              ],
              rows: items.map((x) {
                return DataRow(
                  cells: [
                    DataCell(Text(x['sku']?.toString() ?? '-')),
                    DataCell(Text(x['product_name']?.toString() ?? '-')),
                    DataCell(Text(x['warehouse_code']?.toString() ?? '-')),
                    DataCell(Text(x['location_code']?.toString() ?? '-')),
                    DataCell(Text(x['quantity']?.toString() ?? '0')),
                    DataCell(Text(x['reserved_quantity']?.toString() ?? '0')),
                    DataCell(Text(x['available_quantity']?.toString() ?? '0')),
                    DataCell(Text(x['damaged_quantity']?.toString() ?? '0')),
                  ],
                );
              }).toList(),
            ),
          );

    return _panel('Current Stock', content);
  }

  Widget _stockLedger() {
    final content = txns.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('No transactions found.')),
          )
        : HorizontalTableScroller(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('User')),
              ],
              rows: txns.take(100).map((x) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        x['created_at']?.toString().replaceFirst('T', ' ') ?? '-',
                      ),
                    ),
                    DataCell(Text(x['sku']?.toString() ?? '-')),
                    DataCell(Text(x['warehouse_code']?.toString() ?? '-')),
                    DataCell(Text(x['transaction_type']?.toString() ?? '-')),
                    DataCell(Text(x['quantity']?.toString() ?? '0')),
                    DataCell(Text(x['created_by_name']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          );

    return _panel('Stock Ledger', content);
  }

  Widget _stats() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _card('Stock Lines', items.length, Icons.inventory_2_outlined),
        _card(
          'Units',
          items.fold<double>(
            0,
            (sum, x) =>
                sum + (double.tryParse(x['quantity']?.toString() ?? '0') ?? 0),
          ),
          Icons.numbers_outlined,
        ),
        _card(
          'Available',
          items.fold<double>(
            0,
            (sum, x) =>
                sum +
                (double.tryParse(
                      x['available_quantity']?.toString() ?? '0',
                    ) ??
                    0),
          ),
          Icons.check_circle_outline,
        ),
        _card(
          'Damaged',
          items.fold<double>(
            0,
            (sum, x) =>
                sum +
                (double.tryParse(
                      x['damaged_quantity']?.toString() ?? '0',
                    ) ??
                    0),
          ),
          Icons.warning_amber_outlined,
        ),
        _card('Transactions', txns.length, Icons.history),
      ],
    );
  }

  Widget _card(String title, num value, IconData icon) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(15),
      decoration: _box(),
      child: Row(
        children: [
          Icon(icon, size: 27, color: const Color(0xFF1769E8)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value is double ? value.toStringAsFixed(2) : value.toString(),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF162B46),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8F1)),
    );
  }

  Widget _error() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error ?? 'Unable to load inventory.'),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
