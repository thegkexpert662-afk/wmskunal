import 'package:flutter/material.dart';

const wmsBlue = Color(0xFF0B8FBD);
const wmsDark = Color(0xFF075B7A);
const wmsPale = Color(0xFFEAF8FC);

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, required this.subtitle, this.actions = const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF17323E))),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: Color(0xFF70858F))),
            ],
          ),
        ),
        if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 12), child: Wrap(spacing: 8, runSpacing: 8, children: actions)),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))), if (trailing != null) trailing!]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  final List<List<String>> items;
  const SummaryCards({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth < 650 ? (constraints.maxWidth - 12) / 2 : 165;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((List<String> item) => SizedBox(
            width: width,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(item[0], style: const TextStyle(fontSize: 11, color: Color(0xFF74868E))),
                  const SizedBox(height: 4),
                  Text(item[1], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: wmsDark)),
                ]),
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  const StatusBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Color color = wmsBlue;
    if (<String>{'Active', 'Approved', 'Completed', 'Delivered', 'Sent', 'Available', 'Success'}.contains(text)) {
      color = Colors.green.shade700;
    } else if (<String>{'Pending', 'On Hold', 'QC Hold', 'Low Stock'}.contains(text)) {
      color = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class DataTableCard extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int> statusColumns;

  const DataTableCard({super.key, required this.headers, required this.rows, this.statusColumns = const <int>[]});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all<Color>(wmsPale),
          columns: headers.map((String header) => DataColumn(label: Text(header, style: const TextStyle(fontWeight: FontWeight.w800)))).toList(),
          rows: rows.map((List<String> row) => DataRow(
            cells: List<DataCell>.generate(row.length, (int index) => DataCell(
              statusColumns.contains(index) ? StatusBadge(row[index]) : Text(row[index], style: const TextStyle(fontSize: 12)),
            )),
          )).toList(),
        ),
      ),
    );
  }
}

class ScreenFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  const ScreenFrame({super.key, required this.title, required this.subtitle, required this.child, this.actions = const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(title: title, subtitle: subtitle, actions: actions),
              const SizedBox(height: 22),
              child,
            ],
          ),
        );
      },
    );
  }
}
