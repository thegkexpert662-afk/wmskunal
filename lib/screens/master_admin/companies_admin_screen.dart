import 'package:flutter/material.dart';
import '../common_widgets.dart';

class CompaniesAdminScreen extends StatelessWidget {
  const CompaniesAdminScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Companies / Admin Management',
    subtitle: 'Manage company tenants, administrative access and company status.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 14, children: [
        SettingCard(title: 'Companies', icon: Icons.business_outlined),
        SettingCard(title: 'Admin Accounts', icon: Icons.admin_panel_settings_outlined),
        SettingCard(title: 'Company Access', icon: Icons.lock_outline),
      ]),
      SizedBox(height: 20),
      Card(child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(children: [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(child: Text('Operational orders, stock, invoices and client business data are not displayed in Master Admin.')),
        ]),
      )),
    ]),
  );
}
