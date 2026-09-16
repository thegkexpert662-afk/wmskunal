import 'package:flutter/material.dart';
import 'common_widgets.dart';

class GateScreen extends StatelessWidget {
  const GateScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Gate In / Out', subtitle: 'Vehicle entry, exit and gate movement records.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Gate Entry'))], child: Column(children: [SummaryCards(items: const [['Today In', '34'], ['Today Out', '28'], ['At Gate', '06'], ['Pending', '04']]), const SizedBox(height: 18), const DataTableCard(headers: ['Gate ID', 'Vehicle No', 'Client', 'Type', 'Time', 'Status'], rows: [['GT-0081', 'MH04AB1234', 'ABC Industries', 'Inward', '09:12 AM', 'Inside'], ['GT-0080', 'GJ16XY7821', 'Prime Traders', 'Outward', '10:30 AM', 'Exited'], ['GT-0079', 'MH43CD2211', 'Metro Retail', 'Inward', '11:05 AM', 'Inside'], ['GT-0078', 'GJ05KL9910', 'Global Parts', 'Outward', '12:15 PM', 'Pending']], statusColumns: [5])])));
}
