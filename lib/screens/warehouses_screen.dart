import 'package:flutter/material.dart';
import 'common_widgets.dart';

class WarehousesScreen extends StatelessWidget {
  const WarehousesScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Warehouses', subtitle: 'Warehouse, zone, rack, shelf and bin master.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Warehouse'))], child: const DataTableCard(headers: ['WH ID', 'Warehouse', 'Code', 'City', 'Zones', 'Bins', 'Status'], rows: [['WH-001', 'Main Warehouse', 'WH-A', 'Bhiwandi', '12', '840', 'Active'], ['WH-002', 'North Warehouse', 'WH-B', 'Mumbai', '08', '520', 'Active'], ['WH-003', 'Central Warehouse', 'WH-C', 'Ankleshwar', '10', '620', 'Active'], ['WH-004', 'Client Warehouse', 'WH-D', 'Vilayat', '06', '310', 'Active']], statusColumns: [6]));
}
