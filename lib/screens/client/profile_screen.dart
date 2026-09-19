import 'package:flutter/material.dart';
import '../../common_widgets.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Profile',
      subtitle: 'View the logged-in client profile and account information.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Account information',
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 42),
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
