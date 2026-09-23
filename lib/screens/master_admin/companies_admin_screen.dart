import 'package:flutter/material.dart';
import '../../services/company_service.dart';
import '../common_widgets.dart';

class CompaniesAdminScreen extends StatefulWidget {
  const CompaniesAdminScreen({super.key});
  @override
  State<CompaniesAdminScreen> createState() => _CompaniesAdminScreenState();
}

class _CompaniesAdminScreenState extends State<CompaniesAdminScreen> {
  final api = CompanyService.instance;
  List<Map<String, dynamic>> companies = [];
  bool loading = true;
  String search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      companies = await api.list();
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCompanyForm([Map<String, dynamic>? old]) async {
    final code = TextEditingController(text: old?['company_code']?.toString() ?? '');
    final name = TextEditingController(text: old?['name']?.toString() ?? '');
    final logo = TextEditingController(text: old?['logo_url']?.toString() ?? '');
    final address = TextEditingController(text: old?['address']?.toString() ?? '');
    final gstin = TextEditingController(text: old?['gstin']?.toString() ?? '');
    final email = TextEditingController(text: old?['email']?.toString() ?? '');
    final mobile = TextEditingController(text: old?['mobile']?.toString() ?? '');

    try {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(old == null ? 'Create Company' : 'Edit Company'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _field(code, 'Company Code', enabled: old == null)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(name, 'Company Name')),
                  ]),
                  _field(logo, 'Logo URL (optional)'),
                  _field(address, 'Address', maxLines: 3),
                  Row(children: [
                    Expanded(child: _field(gstin, 'GSTIN')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(mobile, 'Mobile')),
                  ]),
                  _field(email, 'Email'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                  _message('Company code and company name are required.');
                  return;
                }
                try {
                  final data = <String, dynamic>{
                    'companyCode': code.text.trim(),
                    'name': name.text.trim(),
                    if (logo.text.trim().isNotEmpty) 'logoUrl': logo.text.trim(),
                    if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
                    if (gstin.text.trim().isNotEmpty) 'gstin': gstin.text.trim(),
                    if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
                    if (mobile.text.trim().isNotEmpty) 'mobile': mobile.text.trim(),
                  };
                  if (old == null) {
                    await api.create(data);
                  } else {
                    data.remove('companyCode');
                    await api.update(old['id'].toString(), data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                  _message(old == null ? 'Company created successfully.' : 'Company updated successfully.');
                } catch (e) {
                  _message(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: Text(old == null ? 'Create Company' : 'Save Changes'),
            ),
          ],
        ),
      );
    } finally {
      code.dispose(); name.dispose(); logo.dispose(); address.dispose();
      gstin.dispose(); email.dispose(); mobile.dispose();
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> company) async {
    try {
      await api.setStatus(company['id'].toString(), company['is_active'] != true);
      await _load();
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openModules(Map<String, dynamic> company) async {
    try {
      var modules = await api.modules(company['id'].toString());
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('Module Access — ' + (company['name']?.toString() ?? '-')),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  children: modules.map((m) => SwitchListTile(
                    dense: true,
                    title: Text(_moduleLabel(m['moduleKey']?.toString() ?? '-')),
                    subtitle: Text(m['moduleKey']?.toString() ?? ''),
                    value: m['isEnabled'] == true,
                    onChanged: (value) => setDialogState(() => m['isEnabled'] = value),
                  )).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    await api.updateModules(
                      company['id'].toString(),
                      modules.map((m) => {
                        'moduleKey': m['moduleKey'].toString(),
                        'isEnabled': m['isEnabled'] == true,
                      }).toList(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _message('Company module access updated.');
                  } catch (e) {
                    _message(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: const Text('Save Modules'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _moduleLabel(String key) {
    const labels = {
      'gate': 'Gate', 'inbound': 'Inbound', 'grn': 'GRN', 'qc': 'Quality Control',
      'putaway': 'Putaway', 'warehouse': 'Warehouse', 'product': 'Products',
      'inventory': 'Inventory', 'order': 'Orders', 'picking': 'Picking',
      'packing': 'Packing', 'dispatch': 'Dispatch', 'return': 'Returns',
      'invoice': 'Invoices', 'report': 'Reports', 'client': 'Clients',
      'stock_transfer': 'Stock Transfer',
    };
    return labels[key] ?? key;
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return companies;
    return companies.where((c) {
      return [c['company_code'], c['name'], c['email'], c['gstin']]
          .join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Companies / Admin Management',
      subtitle: 'Manage company tenants, status, module access and company details.',
      actions: [
        FilledButton.icon(
          onPressed: () => _openCompanyForm(),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Add Company'),
        ),
        IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_stats(), const SizedBox(height: 16), _table()],
            ),
    );
  }

  Widget _stats() => Wrap(
    spacing: 12, runSpacing: 12,
    children: [
      _stat('Companies', companies.length, Icons.business_outlined),
      _stat('Active', companies.where((c) => c['is_active'] == true).length, Icons.check_circle_outline),
      _stat('Inactive', companies.where((c) => c['is_active'] != true).length, Icons.pause_circle_outline),
    ],
  );

  Widget _stat(String title, int value, IconData icon) => Container(
    width: 210, padding: const EdgeInsets.all(14), decoration: _box(),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF1769E8), size: 28), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      ]),
    ]),
  );

  Widget _table() => Container(
    decoration: _box(), padding: const EdgeInsets.all(12),
    child: Column(children: [
      TextField(
        onChanged: (v) => setState(() => search = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search company, code, email or GSTIN'),
      ),
      const Divider(height: 24),
      if (filtered.isEmpty)
        const Padding(padding: EdgeInsets.all(30), child: Text('No companies found. Create your first company.'))
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Company Code')), DataColumn(label: Text('Company')),
              DataColumn(label: Text('GSTIN')), DataColumn(label: Text('Email')),
              DataColumn(label: Text('Status')), DataColumn(label: Text('Actions')),
            ],
            rows: filtered.map((c) {
              final active = c['is_active'] == true;
              return DataRow(cells: [
                DataCell(Text(c['company_code']?.toString() ?? '-')),
                DataCell(Text(c['name']?.toString() ?? '-')),
                DataCell(Text(c['gstin']?.toString() ?? '-')),
                DataCell(Text(c['email']?.toString() ?? '-')),
                DataCell(Text(active ? 'Active' : 'Inactive')),
                DataCell(Row(children: [
                  IconButton(tooltip: 'Edit', onPressed: () => _openCompanyForm(c), icon: const Icon(Icons.edit_outlined)),
                  IconButton(tooltip: 'Module Access', onPressed: () => _openModules(c), icon: const Icon(Icons.tune_outlined)),
                  IconButton(
                    tooltip: 'Activate / Deactivate',
                    onPressed: () => _toggleStatus(c),
                    icon: Icon(active ? Icons.pause_circle_outline : Icons.play_circle_outline),
                  ),
                ])),
              ]);
            }).toList(),
          ),
        ),
    ]),
  );

  Widget _field(TextEditingController controller, String label, {bool enabled = true, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: controller, enabled: enabled, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE1E8F1)),
  );
}
