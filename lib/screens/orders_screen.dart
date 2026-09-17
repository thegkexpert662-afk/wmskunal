import 'package:flutter/material.dart';

import 'common_widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Client Orders',
      subtitle: 'Manage orders from acceptance through dispatch.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New Order'),
        ),
      ],
      child: Column(
        children: <Widget>[
          SummaryCards(
            items: const <List<String>>[
              <String>['New', '12'],
              <String>['Processing', '24'],
              <String>['Picking', '18'],
              <String>['Ready', '08'],
            ],
          ),
          const SizedBox(height: 18),
          const DataTableCard(
            headers: <String>[
              'Order ID',
              'Client',
              'Items',
              'Qty',
              'Order Date',
              'Required',
              'Status',
            ],
            rows: <List<String>>[
              <String>[
                'ORD-10284',
                'ABC Industries',
                '04',
                '580',
                '16 Sep',
                '17 Sep',
                'Processing',
              ],
              <String>[
                'ORD-10283',
                'Metro Retail',
                '08',
                '1,240',
                '16 Sep',
                '18 Sep',
                'Picking',
              ],
              <String>[
                'ORD-10282',
                'Prime Traders',
                '03',
                '760',
                '15 Sep',
                '17 Sep',
                'Dispatched',
              ],
              <String>[
                'ORD-10281',
                'Global Parts',
                '06',
                '420',
                '15 Sep',
                '19 Sep',
                'Pending',
              ],
            ],
            statusColumns: <int>[6],
          ),
        ],
      ),
    );
  }
}
