import 'package:flutter/material.dart';
import 'common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Settings', subtitle: 'Company, brand, invoice, warehouse and application configuration.', child: Column(children: const [SettingCard(title: 'Company Settings', icon: Icons.business_outlined), SizedBox(height: 14), SettingCard(title: 'Invoice Settings', icon: Icons.receipt_long_outlined), SizedBox(height: 14), SettingCard(title: 'Warehouse Settings', icon: Icons.warehouse_outlined), SizedBox(height: 14), SettingCard(title: 'Notification Settings', icon: Icons.notifications_none_outlined)]));
}

class SettingCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const SettingCard({super.key, required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => SectionCard(title: title, child: Wrap(spacing: 12, runSpacing: 12, children: [const SizedBox(width: 230, child: TextField(decoration: InputDecoration(labelText: 'Name / Value'))), const SizedBox(width: 230, child: TextField(decoration: InputDecoration(labelText: 'Configuration'))), FilledButton(onPressed: () {}, child: const Text('Save Changes'))]));
}
