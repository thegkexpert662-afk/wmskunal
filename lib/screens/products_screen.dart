import 'package:flutter/material.dart';
import 'common_widgets.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Products / Material Master', subtitle: 'SKU, UOM, category, client mapping and stock rules.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Product'))], child: const DataTableCard(headers: ['SKU', 'Product', 'Client', 'Category', 'UOM', 'Min Stock', 'Status'], rows: [['SKU-1001', 'Polymer Resin', 'ABC Industries', 'Raw Material', 'KG', '500', 'Active'], ['SKU-1002', 'Packaging Box', 'Metro Retail', 'Packaging', 'PCS', '200', 'Active'], ['SKU-1003', 'Chemical RM', 'Prime Traders', 'Raw Material', 'KG', '300', 'Active'], ['SKU-1004', 'Finished Goods', 'Global Parts', 'Finished Goods', 'PCS', '100', 'Active']], statusColumns: [6]));
}
