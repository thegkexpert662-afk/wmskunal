import 'package:flutter/material.dart';
import 'common_widgets.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Clients', subtitle: 'Client master, brand assignment and warehouse access.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add_business), label: const Text('Add Client'))], child: const DataTableCard(headers: ['Client ID', 'Client Name', 'Brand', 'Warehouse', 'Contact', 'Orders', 'Status'], rows: [['CL-001', 'ABC Industries', 'Brand A', 'WH-A', 'admin@abc.com', '128', 'Active'], ['CL-002', 'Metro Retail', 'Brand A', 'WH-B', 'ops@metro.com', '96', 'Active'], ['CL-003', 'Prime Traders', 'Brand B', 'WH-A', 'store@prime.com', '74', 'Active'], ['CL-004', 'Global Parts', 'Brand B', 'WH-C', 'logistics@global.com', '52', 'Active']], statusColumns: [6]));
}
