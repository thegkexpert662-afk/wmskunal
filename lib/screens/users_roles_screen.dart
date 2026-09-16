import 'package:flutter/material.dart';
import 'common_widgets.dart';

class UsersRolesScreen extends StatelessWidget {
  const UsersRolesScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Users & Roles', subtitle: 'Role-based access for company, brand and client users.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_outlined), label: const Text('Add User'))], child: const DataTableCard(headers: ['User', 'Email', 'Role', 'Scope', 'Last Login', 'Status'], rows: [['Admin User', 'admin@kopersay.com', 'Company Admin', 'All Brands', 'Today', 'Active'], ['Manager A', 'manager.a@kopersay.com', 'Brand Manager', 'Brand A', 'Today', 'Active'], ['Manager B', 'manager.b@kopersay.com', 'Brand Manager', 'Brand B', 'Today', 'Active'], ['Client A1', 'admin@abc.com', 'Client User', 'ABC Industries', 'Today', 'Active']], statusColumns: [5]));
}
