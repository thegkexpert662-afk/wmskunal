import 'package:flutter/material.dart';
import '../common_widgets.dart';

class ClientMyOrdersScreen extends StatelessWidget {
  const ClientMyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Orders',
      subtitle: 'View orders placed by the logged-in client.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search order number or status',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 42),
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
