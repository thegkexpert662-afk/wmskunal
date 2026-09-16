import 'package:flutter/material.dart';
import 'common_widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Client Orders', subtitle: 'Manage orders from acceptance through dispatch.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('New Order'))], child: Column(children: [SummaryCards(items: const [['New', '12'], ['Processing', '24'], ['Picking', '18'], ['Ready', '08']]), const SizedBox(height: 18), const DataTableCard(headers: ['Order ID', 'Client', 'Items', 'Qty', 'Order Date', 'Required', 'Status'], rows: [['ORD-10284', 'ABC Industries', '04', '580', '16 Sep', '17 Sep', 'Processing'], ['ORD-10283', 'Metro Retail', '08', '1,240', '16 Sep', '18 Sep', 'Picking'], ['ORD-10282', 'Prime Traders', '03', '760', '15 Sep', '17 Sep', 'Dispatched'], ['ORD-10281', 'Global Parts', '06', '420', '15 Sep', '19 Sep', 'Pending']], statusColumns: [6])])));
}
