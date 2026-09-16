import 'package:flutter/material.dart';
import 'common_widgets.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Invoices', subtitle: 'Invoice generation, PDF and client billing history.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.receipt_long_outlined), label: const Text('Generate Invoice'))], child: const DataTableCard(headers: ['Invoice No', 'Client', 'Order', 'Amount', 'Date', 'PDF', 'Email'], rows: [['INV-2026-081', 'ABC Industries', 'ORD-10284', '₹2,84,500', '16 Sep', 'Ready', 'Sent'], ['INV-2026-080', 'Metro Retail', 'ORD-10283', '₹1,72,800', '16 Sep', 'Ready', 'Sent'], ['INV-2026-079', 'Prime Traders', 'ORD-10282', '₹98,400', '15 Sep', 'Ready', 'Pending'], ['INV-2026-078', 'Global Parts', 'ORD-10281', '₹76,250', '15 Sep', 'Ready', 'Sent']], statusColumns: [5, 6]));
}
