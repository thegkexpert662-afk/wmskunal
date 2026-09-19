import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Reports',
      subtitle: 'Operational and client-wise reporting center.',
      child: LayoutBuilder(
        builder: (_, constraints) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth < 650 ? 2 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: const [
              ReportTile(
                title: 'Inventory Report',
                icon: Icons.inventory_2_outlined,
              ),
              ReportTile(
                title: 'Stock Ledger',
                icon: Icons.history_outlined,
              ),
              ReportTile(
                title: 'GRN Report',
                icon: Icons.move_to_inbox_outlined,
              ),
              ReportTile(
                title: 'Dispatch Report',
                icon: Icons.local_shipping_outlined,
              ),
              ReportTile(
                title: 'Order Report',
                icon: Icons.shopping_cart_outlined,
              ),
              ReportTile(
                title: 'Invoice Report',
                icon: Icons.receipt_long_outlined,
              ),
              ReportTile(
                title: 'Client Report',
                icon: Icons.business_outlined,
              ),
              ReportTile(
                title: 'Email Status',
                icon: Icons.email_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReportTile extends StatelessWidget {
  final String title;
  final IconData icon;

  const ReportTile({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title opened.')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: wmsBlue, size: 34),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'View / Export',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF73858D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
