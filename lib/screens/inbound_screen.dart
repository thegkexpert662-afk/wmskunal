import 'package:flutter/material.dart';
import 'common_widgets.dart';

class InboundScreen extends StatelessWidget {
  const InboundScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Inbound / GRN', subtitle: 'Receive material, create GRN and approve stock.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Create GRN'))], child: Column(children: [SummaryCards(items: const [['GRN Today', '128'], ['Pending QC', '12'], ['Pending Approval', '06'], ['Completed', '110']]), const SizedBox(height: 18), const DataTableCard(headers: ['GRN No', 'Client', 'PO No', 'Material', 'Qty', 'Date', 'Status'], rows: [['GRN-24081', 'ABC Industries', 'PO-8831', 'RM-1001', '500', '16 Sep', 'Approved'], ['GRN-24080', 'Metro Retail', 'PO-8830', 'FG-2022', '320', '16 Sep', 'QC Hold'], ['GRN-24079', 'Prime Traders', 'PO-8829', 'RM-4010', '760', '16 Sep', 'Pending']], statusColumns: [6])])));
}
