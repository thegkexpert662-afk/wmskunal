import 'package:flutter/material.dart';
import '../../common_widgets.dart';

class ClientTrackDispatchScreen extends StatelessWidget {
  const ClientTrackDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Track Dispatch',
      subtitle: 'Track dispatch status and shipment milestones.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter order or dispatch number',
              prefixIcon: const Icon(Icons.local_shipping_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 42),
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
