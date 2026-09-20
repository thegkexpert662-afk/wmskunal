import 'package:flutter/material.dart';
import '../common_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController search = TextEditingController();
  String status = 'All';
  String category = 'All';

  final List<List<String>> products = const [
    ['SKU-1001', 'Polymer Resin', 'ABC Industries', 'Raw Material', 'KG', '500', 'Active', '₹ 8,42,500'],
    ['SKU-1002', 'Packaging Box', 'Metro Retail', 'Packaging', 'PCS', '200', 'Active', '₹ 2,18,400'],
    ['SKU-1003', 'Chemical RM', 'Prime Traders', 'Raw Material', 'KG', '300', 'Active', '₹ 6,74,200'],
    ['SKU-1004', 'Finished Goods', 'Global Parts', 'Finished Goods', 'PCS', '100', 'Active', '₹ 4,82,750'],
    ['SKU-1005', 'Industrial Drum', 'ABC Industries', 'Packaging', 'PCS', '150', 'Pending', '₹ 1,56,800'],
    ['SKU-1006', 'Specialty Material', 'National Distributors', 'Raw Material', 'KG', '250', 'Inactive', '₹ 98,600'],
  ];

  List<List<String>> get filteredProducts {
    final String query = search.text.toLowerCase().trim();
    return products.where((row) {
      final bool matchesSearch = query.isEmpty || row.any((value) => value.toLowerCase().contains(query));
      final bool matchesStatus = status == 'All' || row[6] == status;
      final bool matchesCategory = category == 'All' || row[3] == category;
      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 1100;

    return ScreenFrame(
      title: 'Products / Material Master',
      subtitle: 'Manage SKU, UOM, category, client mapping and stock rules.',
      actions: [
        FilledButton.icon(
          onPressed: () => _showMessage('Add Product form opened.'),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Add Product'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryCards(compact),
          const SizedBox(height: 16),
          if (compact)
            Column(
              children: [
                _productTable(),
                const SizedBox(height: 14),
                _productDetails(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _productTable()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _productDetails()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryCards(bool compact) {
    final List<Widget> cards = [
      _summaryCard('Total Products', '126', 'All SKUs', Icons.inventory_2_outlined, const Color(0xFF1769E8), const Color(0xFFEAF2FF)),
      _summaryCard('Active Products', '118', '93.6% Active', Icons.verified_outlined, const Color(0xFF16A05D), const Color(0xFFE7F9EF)),
      _summaryCard('Low Stock', '07', 'Needs Attention', Icons.warning_amber_rounded, const Color(0xFFE39A0A), const Color(0xFFFFF4DE)),
      _summaryCard('Inactive', '01', 'Currently Disabled', Icons.inventory_outlined, const Color(0xFFE83C55), const Color(0xFFFFE9ED)),
      _summaryCard('Stock Value', '₹ 48,75,650', 'Current Value', Icons.currency_rupee_rounded, const Color(0xFF7447D8), const Color(0xFFF0EAFF)),
    ];

    if (compact) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.25,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _summaryCard(String title, String value, String subtitle, IconData icon, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _boldText(12)),
                const SizedBox(height: 3),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: _boldText(22)),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF738298), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productTable() {
    return _panel(
      'Product List',
      Column(
        children: [
          _filters(),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Color(0xFF43546A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFF26384F),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              headingRowHeight: 48,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              columnSpacing: 26,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
              columns: const [
                DataColumn(columnWidth: const FixedColumnWidth(50), label: Text('#')),
                DataColumn(columnWidth: const FixedColumnWidth(110), label: Text('SKU')),
                DataColumn(columnWidth: const FixedColumnWidth(180), label: Text('Product')),
                DataColumn(columnWidth: const FixedColumnWidth(160), label: Text('Client')),
                DataColumn(columnWidth: const FixedColumnWidth(120), label: Text('Category')),
                DataColumn(columnWidth: const FixedColumnWidth(80), label: Text('UOM')),
                DataColumn(columnWidth: const FixedColumnWidth(95), label: Text('Min Stock')),
                DataColumn(columnWidth: const FixedColumnWidth(105), label: Text('Status')),
                DataColumn(columnWidth: const FixedColumnWidth(115), label: Text('Stock Value')),
                DataColumn(columnWidth: const FixedColumnWidth(90), label: Text('Actions')),
              ],
              rows: List.generate(filteredProducts.length, (index) {
                final List<String> row = filteredProducts[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(row[0], style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(row[1], style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(row[2])),
                    DataCell(Text(row[3])),
                    DataCell(Text(row[4])),
                    DataCell(Text(row[5])),
                    DataCell(_statusChip(row[6])),
                    DataCell(Text(row[7])),
                    DataCell(_viewButton(row[0])),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  'Showing 1 to ${filteredProducts.length} of 126 entries',
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
                ),
                const Spacer(),
                _pageButton('Prev'),
                _pageButton('1', true),
                _pageButton('2'),
                _pageButton('3'),
                _pageButton('4'),
                _pageButton('Next'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 300,
            height: 40,
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: 'Search SKU, product or client...',
                hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF8290A2)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
                ),
              ),
            ),
          ),
          _dropdown(
            value: status,
            items: const ['All', 'Active', 'Pending', 'Inactive'],
            label: 'Status',
            onChanged: (value) {
              if (value != null) {
                setState(() => status = value);
              }
            },
          ),
          _dropdown(
            value: category,
            items: const ['All', 'Raw Material', 'Packaging', 'Finished Goods'],
            label: 'Category',
            onChanged: (value) {
              if (value != null) {
                setState(() => category = value);
              }
            },
          ),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('Filter'),
          ),
          OutlinedButton.icon(
            onPressed: () => _showMessage('Product list exported successfully.'),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDCE4EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF42546A),
            fontWeight: FontWeight.w600,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item == 'All' ? '$label: All' : item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _productDetails() {
    return _panel(
      'Product Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1769E8), size: 25),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Polymer Resin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172A43))),
                      SizedBox(height: 3),
                      Text('SKU-1001 • Raw Material • Active', style: TextStyle(fontSize: 9, color: Color(0xFF718096))),
                    ],
                  ),
                ),
                _statusChip('Active'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Client', 'ABC Industries', Icons.business_outlined),
          _detailRow('UOM', 'KG', Icons.scale_outlined),
          _detailRow('Min Stock', '500 KG', Icons.inventory_outlined),
          _detailRow('Category', 'Raw Material', Icons.category_outlined),
          _detailRow('Stock Value', '₹ 8,42,500', Icons.currency_rupee_rounded),
          _detailRow('Last Updated', '16 Sep 2026', Icons.schedule_outlined),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage('Product edit opened.'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showMessage('Stock details opened.'),
                  icon: const Icon(Icons.inventory_outlined, size: 16),
                  label: const Text('Stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _boldText(14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _statusChip(String value) {
    final bool active = value == 'Active';
    final bool pending = value == 'Pending';
    final Color textColor = active
        ? const Color(0xFF14894E)
        : pending
            ? const Color(0xFFE28C00)
            : const Color(0xFFD92F4B);
    final Color background = active
        ? const Color(0xFFE4F7EC)
        : pending
            ? const Color(0xFFFFF0D8)
            : const Color(0xFFFFE5EA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _viewButton(String sku) {
    return IconButton(
      onPressed: () => _showMessage('Viewing product $sku'),
      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1769E8), size: 17),
      tooltip: 'View',
    );
  }

  Widget _pageButton(String text, [bool active = false]) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      height: 30,
      constraints: const BoxConstraints(minWidth: 30),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1769E8) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? const Color(0xFF1769E8) : const Color(0xFFDDE5EF),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF63738A),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF718096)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 9, color: Color(0xFF718096)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF27394F)),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E8F1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A18304F),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  TextStyle _boldText(double size) {
    return TextStyle(
      color: const Color(0xFF162B46),
      fontSize: size,
      fontWeight: FontWeight.w800,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
