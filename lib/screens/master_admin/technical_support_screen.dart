import 'package:flutter/material.dart';
import '../common_widgets.dart';

class TechnicalSupportScreen extends StatelessWidget {
  const TechnicalSupportScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(
    title: 'Technical Support',
    subtitle: 'System diagnostics, support requests and technical service controls.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 14, children: [
        SettingCard(title: 'Open Support', icon: Icons.support_agent_outlined),
        SettingCard(title: 'System Health', icon: Icons.monitor_heart_outlined),
        SettingCard(title: 'Service Status', icon: Icons.cloud_done_outlined),
      ]),
      SizedBox(height: 20),
      Card(child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('Technical support has system-level visibility only and does not expose operational business documents.')),
        ]),
      )),
    ]),
  );
}
