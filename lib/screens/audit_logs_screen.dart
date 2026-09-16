import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Audit Logs', subtitle: 'Track important user and operational actions.', child: const DataTableCard(headers: ['Time', 'User', 'Module', 'Action', 'Reference', 'Result'], rows: [['19:32', 'Admin User', 'Orders', 'Accepted Order', 'ORD-10284', 'Success'], ['18:55', 'Manager A', 'Inventory', 'Stock Transfer', 'TR-5012', 'Success'], ['18:31', 'Client A1', 'Orders', 'Placed Order', 'ORD-10284', 'Success'], ['17:48', 'Admin User', 'Invoice', 'Generated PDF', 'INV-2026-081', 'Success']]));
}
