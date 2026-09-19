import 'package:flutter/material.dart';
import '../../common_widgets.dart';

class ClientPlaceOrderScreen extends StatelessWidget {
  const ClientPlaceOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Place Order',
      subtitle: 'Create a new client order from authorised products.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search product to add to order',
              prefixIcon: const Icon(Icons.add_shopping_cart_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart_outlined, size: 42),
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
