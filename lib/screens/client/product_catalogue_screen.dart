import 'package:flutter/material.dart';
import '../../common_widgets.dart';

class ClientProductCatalogueScreen extends StatelessWidget {
  const ClientProductCatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Product Catalogue',
      subtitle: 'Search and browse products available to this client.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search SKU, product name or HSN',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 42),
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
