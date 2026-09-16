import 'package:flutter/material.dart';
import 'common_widgets.dart';

class MaterialOutScreen extends StatelessWidget {
  const MaterialOutScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Material Out', subtitle: 'Verify picked material and approve outward movement.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Create Material Out'))], child: const DataTableCard(headers: ['MO No', 'Order ID', 'Client', 'Qty', 'Vehicle', 'Created', 'Status'], rows: [['MO-4008', 'ORD-10284', 'ABC Industries', '580', 'MH04AB1234', '16 Sep', 'Approved'], ['MO-4007', 'ORD-10283', 'Metro Retail', '1,240', 'MH43CD2211', '16 Sep', 'Ready'], ['MO-4006', 'ORD-10282', 'Prime Traders', '760', 'GJ16XY7821', '15 Sep', 'Dispatched'], ['MO-4005', 'ORD-10281', 'Global Parts', '420', '-', '15 Sep', 'Pending']], statusColumns: [6]));
}
