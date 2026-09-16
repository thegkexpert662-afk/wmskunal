import 'package:flutter/material.dart';
import 'common_widgets.dart';

class DispatchScreen extends StatelessWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Dispatch',
      subtitle: 'Dispatch confirmation, transporter and gate-out workflow.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Create Dispatch'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SummaryCards(
            items: <List<String>>[
              <String>['Ready', '18'],
              <String>['Dispatched Today', '96'],
              <String>['In Transit', '42'],
              <String>['Delivered', '36'],
            ],
          ),
          const SizedBox(height: 18),
          const DataTableCard(
            headers: <String>[
              'Dispatch ID',
              'Order',
              'Client',
              'Vehicle',
              'LR No',
              'Date',
              'Status',
            ],
            rows: <List<String>>[
              <String>['DSP-7018', 'ORD-10284', 'ABC Industries', 'MH04AB1234', 'LR-90081', '16 Sep', 'Ready'],
              <String>['DSP-7017', 'ORD-10283', 'Metro Retail', 'MH43CD2211', 'LR-90080', '16 Sep', 'In Transit'],
              <String>['DSP-7016', 'ORD-10282', 'Prime Traders', 'GJ16XY7821', 'LR-90079', '15 Sep', 'Dispatched'],
              <String>['DSP-7015', 'ORD-10281', 'Global Parts', 'MH14EF5555', 'LR-90078', '15 Sep', 'Delivered'],
            ],
            statusColumns: <int>[6],
          ),
        ],
      ),
    );
  }
}
