import 'package:flutter/material.dart';
import 'common_widgets.dart';

class ClientPortalScreen extends StatelessWidget {
  const ClientPortalScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenFrame(title: 'Client Portal', subtitle: 'Client sees only its own catalogue, orders, dispatches and invoices.', child: Column(children: [SummaryCards(items: const [['Open Orders', '08'], ['Processing', '05'], ['Dispatched', '12'], ['Invoices', '24']]), const SizedBox(height: 18), LayoutBuilder(builder: (_, c) => c.maxWidth < 850 ? Column(children: [_actions(), const SizedBox(height: 18), _orders()]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _actions()), const SizedBox(width: 18), Expanded(child: _orders())])), const SizedBox(height: 18), const SectionCard(title: 'My Invoices', child: DataTableCard(headers: ['Invoice', 'Order', 'Amount', 'Date', 'PDF', 'Email'], rows: [['INV-2026-081', 'ORD-10284', '₹2,84,500', '16 Sep', 'Ready', 'Sent'], ['INV-2026-075', 'ORD-10270', '₹1,18,200', '12 Sep', 'Ready', 'Sent'], ['INV-2026-069', 'ORD-10255', '₹86,900', '08 Sep', 'Ready', 'Sent']], statusColumns: [4, 5]))]));
  Widget _actions() => const SectionCard(title: 'Quick Actions', child: Wrap(spacing: 10, runSpacing: 10, children: [FilledButton(onPressed: null, child: Text('Place Order')), OutlinedButton(onPressed: null, child: Text('Catalogue')), OutlinedButton(onPressed: null, child: Text('Track Dispatch'))]));
  Widget _orders() => const SectionCard(title: 'My Recent Orders', child: Column(children: [ListTile(title: Text('ORD-10284'), subtitle: Text('04 items • 580 qty'), trailing: StatusBadge('Processing')), ListTile(title: Text('ORD-10270'), subtitle: Text('08 items • 1,240 qty'), trailing: StatusBadge('Dispatched')), ListTile(title: Text('ORD-10255'), subtitle: Text('03 items • 760 qty'), trailing: StatusBadge('Delivered'))]));
}
