import 'package:flutter/material.dart';
import 'common_widgets.dart';

class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Gate In / Out',
      subtitle: 'Vehicle entry, exit and gate movement records.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Gate Entry'),
        ),
      ],
      child: Column(
        children: <Widget>[
          const SummaryCards(
            items: <List<String>>[
              <String>['Today In', '34'],
              <String>['Today Out', '28'],
              <String>['At Gate', '06'],
              <String>['Pending', '04'],
            ],
          ),
          const SizedBox(height: 18),
          const DataTableCard(
            headers: <String>[
              'Gate ID',
              'Vehicle No',
              'Client',
              'Type',
              'Time',
              'Status',
            ],
            rows: <List<String>>[
              <String>['GT-0081', 'MH04AB1234', 'ABC Industries', 'Inward', '09:12 AM', 'Inside'],
              <String>['GT-0080', 'GJ16XY7821', 'Prime Traders', 'Outward', '10:30 AM', 'Exited'],
              <String>['GT-0079', 'MH43CD2211', 'Metro Retail', 'Inward', '11:05 AM', 'Inside'],
              <String>['GT-0078', 'GJ05KL9910', 'Global Parts', 'Outward', '12:15 PM', 'Pending'],
            ],
            statusColumns: <int>[5],
          ),
        ],
      ),
    );
  }
}
