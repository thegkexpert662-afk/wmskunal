import 'package:flutter/material.dart';
import '../common_widgets.dart';

class AdminReturnsScreen extends StatefulWidget {
  const AdminReturnsScreen({super.key});

  @override
  State<AdminReturnsScreen> createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends State<AdminReturnsScreen> {
  String filter = 'All';

  final List<Map<String, String>> returns = [
    {
      'id': 'RET-2026-0012',
      'order': 'ORD-10458',
      'client': 'ABC Industries',
      'qty': '100',
      'status': 'Return Requested',
      'reason': 'Excess material',
    },
    {
      'id': 'RET-2026-0011',
      'order': 'ORD-10431',
      'client': 'XYZ Packaging',
      'qty': '50',
      'status': 'QC Hold',
      'reason': 'Material damaged',
    },
    {
      'id': 'RET-2026-0009',
      'order': 'ORD-10398',
      'client': 'PQR Traders',
      'qty': '75',
      'status': 'Completed',
      'reason': 'Customer return',
    },
  ];

  List<Map<String, String>> get filteredReturns {
    if (filter == 'All') return returns;
    return returns.where((item) => item['status'] == filter).toList();
  }

  void _showCreateReturn() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Return'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Original Order / Invoice',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ORD-10458',
                    child: Text('ORD-10458 / INV-2026-10458'),
                  ),
                  DropdownMenuItem(
                    value: 'ORD-10431',
                    child: Text('ORD-10431 / INV-2026-10431'),
                  ),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Returned Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Return Reason',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Excess material',
                    child: Text('Excess material'),
                  ),
                  DropdownMenuItem(
                    value: 'Damaged material',
                    child: Text('Damaged material'),
                  ),
                  DropdownMenuItem(
                    value: 'Customer return',
                    child: Text('Customer return'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Return'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredReturns;
    return ScreenFrame(
      title: 'Returns',
      subtitle: 'Manage returned material from dispatched orders and invoices.',
      actions: [
        ElevatedButton.icon(
          onPressed: _showCreateReturn,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Create Return'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCards(
            items: [
              ['Open Returns', '12'],
              ['Gate In Pending', '4'],
              ['QC Hold', '3'],
              ['Completed', '18'],
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [
                'All',
                'Return Requested',
                'Gate In Pending',
                'QC Hold',
                'Completed',
              ])
                ChoiceChip(
                  label: Text(value),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DataTableCard(
            headers: const [
              'Return ID',
              'Order',
              'Client',
              'Qty',
              'Reason',
              'Status',
              'Action',
            ],
            rows: data.map((item) {
              return [
                item['id']!,
                item['order']!,
                item['client']!,
                item['qty']!,
                item['reason']!,
                item['status']!,
                'View / Process',
              ];
            }).toList(),
            statusColumns: const [5],
          ),
          const SizedBox(height: 22),
          const SectionCard(
            title: 'Return Processing Flow',
            child: Text(
              'Dispatch Completed → Return Request → Original Order / Invoice Check → Gate In → QC Inspection → Good Stock / Damaged / Rejected → Stock or Quarantine → Return Completed',
              style: TextStyle(
                color: Color(0xFF43546A),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
