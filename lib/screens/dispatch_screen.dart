import 'package:flutter/material.dart';
import 'common_widgets.dart';

class DispatchScreen extends StatelessWidget {
  const DispatchScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Dispatch', subtitle: 'Dispatch confirmation, transporter and gate-out workflow.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.local_shipping_outlined), label: const Text('Create Dispatch'))], child: Column(children: [SummaryCards(items: const [['Ready', '18'], ['Dispatched Today', '96'], ['In Transit', '42'], ['Delivered', '36']]), const SizedBox(height: 18), const DataTableCard(headers: ['Dispatch ID', 'Order', 'Client', 'Vehicle', 'LR No', 'Date', 'Status'], rows: [['DSP-7018', 'ORD-10284', 'ABC Industries', 'MH04AB1234', 'LR-90081', '16 Sep', 'Ready'], ['DSP-7017', 'ORD-10283', 'Metro Retail', 'MH43CD2211', 'LR-90080', '16 Sep', 'In Transit'], ['DSP-7016', 'ORD-10282', 'Prime Traders', 'GJ16XY7821', 'LR-90079', '15 Sep', 'Dispatched'], ['DSP-7015', 'ORD-10281', 'Global Parts', 'MH14EF5555', 'LR-90078', '15 Sep', 'Delivered']], statusColumns: [6])])));
}
