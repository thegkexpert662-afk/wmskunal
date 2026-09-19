import 'package:flutter/material.dart';

const wmsBlue = Color(0xFF1769E8);
const wmsDark = Color(0xFF162B46);
const wmsPale = Color(0xFFF4F8FC);

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: wmsDark,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF708096)),
        ),
      ],
    );

    if (actions.isEmpty) return heading;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              heading,
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: heading),
            const SizedBox(width: 12),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ],
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: wmsDark,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
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

  const SummaryCards({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 650
            ? (constraints.maxWidth - 12) / 2
            : 165.0;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item[0],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF748296),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item[1],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: wmsDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;

  const StatusBadge(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color color = wmsBlue;

    if (<String>{
      'Active',
      'Approved',
      'Completed',
      'Delivered',
      'Sent',
      'Available',
      'Success',
      'In Stock',
      'Ready',
      'Received',
      'Verified',
    }.contains(text)) {
      color = Colors.green.shade700;
    } else if (<String>{
      'Pending',
      'On Hold',
      'QC Hold',
      'Low Stock',
      'Assigned',
      'In Progress',
      'Processing',
    }.contains(text)) {
      color = Colors.orange.shade800;
    } else if (<String>{
      'Inactive',
      'Cancelled',
      'Out of Stock',
      'Rejected',
    }.contains(text)) {
      color = Colors.red.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class DataTableCard extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int> statusColumns;

  const DataTableCard({
    super.key,
    required this.headers,
    required this.rows,
    this.statusColumns = const <int>[],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A18304F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 58,
            columnSpacing: 26,
            horizontalMargin: 18,
            dividerThickness: 0.7,
            headingRowColor: const WidgetStatePropertyAll(
              Color(0xFFF4F8FC),
            ),
            columns: headers.map((header) {
              return DataColumn(
                label: Text(
                  header,
                  style: const TextStyle(
                    color: Color(0xFF43546A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
            rows: rows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFFF8FBFF);
                  }
                  return rowIndex.isEven ? Colors.white : const Color(0xFFFCFDFE);
                }),
                cells: List<DataCell>.generate(row.length, (index) {
                  final value = row[index];

                  return DataCell(
                    statusColumns.contains(index)
                        ? StatusBadge(value)
                        : Text(
                            value,
                            style: TextStyle(
                              color: const Color(0xFF26384F),
                              fontSize: 11,
                              fontWeight: index == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                  );
                }),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}


class SettingCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const SettingCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 230,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, color: wmsBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: wmsDark,
                  ),
                ),
              ),
            ],
          ),
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

  const ScreenFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(
            constraints.maxWidth < 600 ? 16 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: title,
                subtitle: subtitle,
                actions: actions,
              ),
              const SizedBox(height: 22),
              child,
            ],
          ),
        );
      },
    );
  }
}


class WmsLoadingBlock extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const WmsLoadingBlock({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class WmsTableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;

  const WmsTableSkeleton({
    super.key,
    this.rows = 6,
    this.columns = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Column(
        children: List<Widget>.generate(rows, (rowIndex) {
          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex == rows - 1 ? 0 : 14),
            child: Row(
              children: List<Widget>.generate(columns, (columnIndex) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: columnIndex == columns - 1 ? 0 : 14,
                    ),
                    child: WmsLoadingBlock(
                      height: rowIndex == 0 ? 18 : 14,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class WmsCardSkeleton extends StatelessWidget {
  final int cards;

  const WmsCardSkeleton({
    super.key,
    this.cards = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List<Widget>.generate(cards, (index) {
        return SizedBox(
          width: 165,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  WmsLoadingBlock(width: 80, height: 11),
                  SizedBox(height: 10),
                  WmsLoadingBlock(width: 55, height: 22),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class WmsDashboardSkeleton extends StatelessWidget {
  const WmsDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        WmsCardSkeleton(),
        SizedBox(height: 22),
        WmsTableSkeleton(rows: 5, columns: 5),
      ],
    );
  }
}

class WmsFormSkeleton extends StatelessWidget {
  final int fields;

  const WmsFormSkeleton({
    super.key,
    this.fields = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List<Widget>.generate(fields, (index) {
        return SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              WmsLoadingBlock(width: 90, height: 11),
              SizedBox(height: 8),
              WmsLoadingBlock(height: 48, radius: 10),
            ],
          ),
        );
      }),
    );
  }
}

class WmsInvoiceSkeleton extends StatelessWidget {
  const WmsInvoiceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          WmsLoadingBlock(width: 220, height: 24),
          SizedBox(height: 10),
          WmsLoadingBlock(width: 340, height: 14),
          SizedBox(height: 24),
          WmsLoadingBlock(height: 1),
          SizedBox(height: 22),
          WmsTableSkeleton(rows: 5, columns: 5),
          SizedBox(height: 22),
          WmsLoadingBlock(width: 220, height: 18),
          SizedBox(height: 10),
          WmsLoadingBlock(width: 160, height: 24),
        ],
      ),
    );
  }
}
