import 'package:flutter/material.dart';
import 'common_widgets.dart';

class PickingScreen extends StatelessWidget {
  const PickingScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Picking', subtitle: 'Create and execute picking tasks against approved orders.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.playlist_add), label: const Text('Create Pick List'))], child: Column(children: [SummaryCards(items: const [['Pick Lists', '18'], ['Assigned', '12'], ['In Progress', '31'], ['Completed', '86']]), const SizedBox(height: 18), const DataTableCard(headers: ['Pick ID', 'Order', 'Client', 'Warehouse', 'Lines', 'Picker', 'Status'], rows: [['PICK-5012', 'ORD-10284', 'ABC Industries', 'WH-A', '12', 'Rahul', 'In Progress'], ['PICK-5011', 'ORD-10283', 'Metro Retail', 'WH-B', '18', 'Amit', 'Assigned'], ['PICK-5010', 'ORD-10282', 'Prime Traders', 'WH-A', '08', 'Suresh', 'Completed'], ['PICK-5009', 'ORD-10281', 'Global Parts', 'WH-C', '11', '-', 'Pending']], statusColumns: [6])])));
}
