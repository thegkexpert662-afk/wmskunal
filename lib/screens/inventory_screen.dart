import 'package:flutter/material.dart';
import 'common_widgets.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Inventory', subtitle: 'Stock by client, warehouse, SKU and batch.', actions: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined), label: const Text('Export'))], child: Column(children: [SummaryCards(items: const [['Stock Items', '12,840'], ['Available', '11,920'], ['Low Stock', '16'], ['On Hold', '09']]), const SizedBox(height: 18), const DataTableCard(headers: ['SKU', 'Material', 'Client', 'Warehouse', 'Batch', 'Qty', 'UOM', 'Status'], rows: [['SKU-1001', 'Polymer Resin', 'ABC Industries', 'WH-A', 'B24091', '2,450', 'KG', 'Available'], ['SKU-1002', 'Packaging Box', 'Metro Retail', 'WH-B', 'B24092', '1,280', 'PCS', 'Available'], ['SKU-1003', 'Chemical RM', 'Prime Traders', 'WH-A', 'B24088', '760', 'KG', 'On Hold'], ['SKU-1004', 'Finished Goods', 'Global Parts', 'WH-C', 'B24077', '320', 'PCS', 'Low Stock']], statusColumns: [7])])));
}
