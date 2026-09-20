import 'package:flutter/material.dart';
import '../common_widgets.dart';

class ClientReturnsScreen extends StatefulWidget {
  const ClientReturnsScreen({super.key});

  @override
  State<ClientReturnsScreen> createState() => _ClientReturnsScreenState();
}

class _ClientReturnsScreenState extends State<ClientReturnsScreen> {
  void _showReturnRequest() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Material Return'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Order / Invoice',
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
                  labelText: 'Return Quantity',
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
                    value: 'Wrong material',
                    child: Text('Wrong material'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
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
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Returns',
      subtitle: 'Request and track material returns for your account.',
      actions: [
        ElevatedButton.icon(
          onPressed: _showReturnRequest,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Request Return'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCards(
            items: [
              ['Requested', '2'],
              ['In Process', '1'],
              ['Completed', '5'],
              ['Rejected', '0'],
            ],
          ),
          const SizedBox(height: 22),
          DataTableCard(
            headers: const [
              'Return ID',
              'Order',
              'Invoice',
              'Qty',
              'Reason',
              'Status',
            ],
            rows: const [
              [
                'RET-2026-0012',
                'ORD-10458',
                'INV-2026-10458',
                '100',
                'Excess material',
                'Return Requested',
              ],
              [
                'RET-2026-0007',
                'ORD-10320',
                'INV-2026-10320',
                '40',
                'Customer return',
                'Completed',
              ],
            ],
            statusColumns: [5],
          ),
          const SizedBox(height: 22),
          const SectionCard(
            title: 'What happens after you submit?',
            child: Text(
              'Your request is checked against the original order/invoice. After approval, returned material enters Gate In and QC. The WMS records the quantity as Good Stock, Damaged, or Rejected and updates the return status.',
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
