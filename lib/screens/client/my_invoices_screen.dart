import 'package:flutter/material.dart';
import '../common_widgets.dart';

class ClientMyInvoicesScreen extends StatelessWidget {
  const ClientMyInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Invoices',
      subtitle: 'View invoices issued to the logged-in client.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search invoice number',
              prefixIcon: const Icon(Icons.description_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 42),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('This client screen is isolated from other client accounts. Data will be loaded from the secured WMS API.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
