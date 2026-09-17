import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 22),
          _summaryCards(context),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _inventorySummary(),
                    const SizedBox(height: 18),
                    _inventoryTrend(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _inventorySummary()),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: _inventoryTrend()),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _recentActivities(),
                    const SizedBox(height: 18),
                    _stockAlerts(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _recentActivities()),
                  const SizedBox(width: 18),
                  Expanded(child: _stockAlerts()),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          _systemStatus(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF101C31),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Overview of your warehouse operations',
                style: TextStyle(color: Color(0xFF667085), fontSize: 14),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 700)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE1E6EF)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF667085)),
                SizedBox(width: 9),
                Text('May 19 – May 25, 2025', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 12),
                Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryCards(BuildContext context) {
    final cards = [
      _MetricData(Icons.warehouse_outlined, 'Total Warehouses', '8', 'Active Warehouses', const Color(0xFF1463D6), const Color(0xFFEAF2FF)),
      _MetricData(Icons.groups_outlined, 'Total Employees', '45', 'Active Employees', const Color(0xFF20A85A), const Color(0xFFEAF9F0)),
      _MetricData(Icons.inventory_2_outlined, 'Total Inventory Items', '12,540', 'Total Items', const Color(0xFF7046D8), const Color(0xFFF1ECFF)),
      _MetricData(Icons.assignment_outlined, "Today's Dispatches", '28', 'Total Orders', const Color(0xFFF08A16), const Color(0xFFFFF4E5)),
      _MetricData(Icons.trending_up, 'Total Stock Value', '₹ 24.5 Lakh', 'Total Inventory Value', const Color(0xFF21A6B5), const Color(0xFFE9FAFC)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 650) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.25,
            children: cards.map(_metricCard).toList(),
          );
        }
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: _metricCard(cards[i])),
              if (i != cards.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _metricCard(_MetricData data) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102040), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: data.iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(data.icon, color: data.iconColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
                const SizedBox(height: 5),
                FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(data.value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF101828)))),
                const SizedBox(height: 3),
                Text(data.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF667085))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventorySummary() {
    return _panel(
      title: 'Inventory Summary',
      child: SizedBox(
        height: 250,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: CustomPaint(
                painter: _DonutPainter(),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('12,540', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF101828))),
                      SizedBox(height: 2),
                      Text('Total Items', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _LegendRow('In Stock', '8,460 (67%)', Color(0xFF246BDE)),
                  SizedBox(height: 20),
                  _LegendRow('Low Stock', '2,150 (17%)', Color(0xFFFFA515)),
                  SizedBox(height: 20),
                  _LegendRow('Out of Stock', '1,940 (16%)', Color(0xFFEF334E)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryTrend() {
    return _panel(
      title: 'Inventory Trend (Last 7 Days)',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DotLegend('In Stock', Color(0xFF246BDE)),
          SizedBox(width: 16),
          _DotLegend('Inward', Color(0xFF21A968)),
          SizedBox(width: 16),
          _DotLegend('Outward', Color(0xFFF58A13)),
        ],
      ),
      child: SizedBox(
        height: 250,
        child: CustomPaint(
          painter: _LineChartPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _recentActivities() {
    return _panel(
      title: 'Recent Activities',
      trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      child: Column(
        children: const [
          _ActivityRow(Icons.description_outlined, Color(0xFF20A85A), 'GRN GRN-25-0501 added by Rakesh', '2 minutes ago'),
          _ActivityRow(Icons.local_shipping_outlined, Color(0xFFEF334E), 'Dispatch DIS-25-0301 created by Mohan', '15 minutes ago'),
          _ActivityRow(Icons.person_outline, Color(0xFF2676D9), 'Employee Suresh Kumar added', '1 hour ago'),
          _ActivityRow(Icons.inventory_2_outlined, Color(0xFFF28A18), 'Stock updated for Item BG-1001', '2 hours ago'),
          _ActivityRow(Icons.warehouse_outlined, Color(0xFF7046D8), 'Warehouse WH-03 created', '3 hours ago'),
        ],
      ),
    );
  }

  Widget _stockAlerts() {
    return _panel(
      title: 'Stock Alerts',
      trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      child: Column(
        children: [
          _alertBox(Icons.warning_amber_rounded, const Color(0xFFE53935), const Color(0xFFFFEEEE), '3 items are Out of Stock'),
          const SizedBox(height: 12),
          _alertBox(Icons.warning_amber_rounded, const Color(0xFFF29B16), const Color(0xFFFFF7E9), '5 items are Low in Stock'),
        ],
      ),
    );
  }

  Widget _alertBox(IconData icon, Color color, Color background, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 29),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _systemStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: const [
          _StatusItem(Icons.verified_user_outlined, 'All systems operational'),
          _StatusItem(Icons.backup_outlined, 'Last backup: 2 hours ago'),
          _StatusItem(Icons.storage_outlined, 'Database: Connected'),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: const [BoxShadow(color: Color(0x08102040), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101828)))),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color iconColor;
  final Color iconBackground;

  const _MetricData(this.icon, this.title, this.value, this.caption, this.iconColor, this.iconBackground);
}

class _LegendRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _LegendRow(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF344054)))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF344054))),
      ],
    );
  }
}

class _DotLegend extends StatelessWidget {
  final String text;
  final Color color;

  const _DotLegend(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF475467))),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String time;

  const _ActivityRow(this.icon, this.color, this.text, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF98A2B3))),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B7D45)),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF344054), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .32;
    final stroke = radius * .42;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke;
    const values = [67.0, 17.0, 16.0];
    const colors = [Color(0xFF246BDE), Color(0xFFFFA515), Color(0xFFEF334E)];
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      paint.color = colors[i];
      final sweep = values[i] / 100 * math.pi * 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep - .025, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  final List<double> stock = [128, 125, 150, 130, 173, 150, 190];
  final List<double> inward = [62, 74, 94, 75, 111, 84, 110];
  final List<double> outward = [21, 34, 22, 31, 42, 33, 43];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 30.0;
    final chart = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final grid = Paint()..color = const Color(0xFFE7EBF1)..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      final label = '${200 - i * 50}';
      final tp = TextPainter(text: TextSpan(text: label, style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(5, y - 6));
    }

    final labels = ['19 May', '20 May', '21 May', '22 May', '23 May', '24 May', '25 May'];
    for (int i = 0; i < labels.length; i++) {
      final x = chart.left + chart.width * i / (labels.length - 1);
      final tp = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chart.bottom + 8));
    }

    _drawSeries(canvas, chart, stock, const Color(0xFF246BDE), 200);
    _drawSeries(canvas, chart, inward, const Color(0xFF21A968), 200);
    _drawSeries(canvas, chart, outward, const Color(0xFFF58A13), 200);
  }

  void _drawSeries(Canvas canvas, Rect chart, List<double> values, Color color, double max) {
    final path = Path();
    final line = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < values.length; i++) {
      final x = chart.left + chart.width * i / (values.length - 1);
      final y = chart.bottom - (values[i] / max) * chart.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = color;
    for (int i = 0; i < values.length; i++) {
      final x = chart.left + chart.width * i / (values.length - 1);
      final y = chart.bottom - (values[i] / max) * chart.height;
      canvas.drawCircle(Offset(x, y), 3.5, dot);
      final inner = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(x, y), 1.4, inner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
