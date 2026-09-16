import 'package:flutter/material.dart';
import 'common_widgets.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Brands', subtitle: 'Multi-brand workspace with isolated client operations.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Brand'))], child: const DataTableCard(headers: ['Brand ID', 'Brand Name', 'Code', 'Clients', 'Warehouses', 'Manager', 'Status'], rows: [['BR-001', 'Brand A', 'BRA', '12', '04', 'Manager A', 'Active'], ['BR-002', 'Brand B', 'BRB', '12', '04', 'Manager B', 'Active']], statusColumns: [6]));
}
