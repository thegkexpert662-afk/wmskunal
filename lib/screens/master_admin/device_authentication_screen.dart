import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common_widgets.dart';

class DeviceAuthenticationScreen extends StatefulWidget {
  const DeviceAuthenticationScreen({super.key});

  @override
  State<DeviceAuthenticationScreen> createState() => _DeviceAuthenticationScreenState();
}

class _DeviceAuthenticationScreenState extends State<DeviceAuthenticationScreen> {
  String statusFilter = 'All';
  final search = TextEditingController();
  List<Map<String, dynamic>> devices = <Map<String, dynamic>>[];
  bool loading = true;
  String? errorMessage;
  String? actionDeviceId;

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadDevices() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final result = await AuthService.instance.getDevices();
      if (!mounted) return;
      setState(() {
        devices = result;
        loading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Unable to load devices. Please try again.';
      });
    }
  }

  Future<void> updateStatus(Map<String, dynamic> device, String status) async {
    final id = device['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => actionDeviceId = id);
    try {
      await AuthService.instance.updateDeviceStatus(
        deviceId: id,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForStatus(status))),
      );
      await loadDevices();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device status update failed.')),
      );
    } finally {
      if (mounted) setState(() => actionDeviceId = null);
    }
  }

  String _messageForStatus(String status) {
    if (status == 'approved') return 'Device approved successfully.';
    if (status == 'rejected') return 'Device rejected.';
    return 'Device access revoked.';
  }

  String _value(Map<String, dynamic> device, String key) =>
      device[key]?.toString() ?? '-';

  String _date(String value) {
    if (value == '-' || value.isEmpty) return '-';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final local = date.toLocal();
    return local.day.toString().padLeft(2, '0') +
        ' ' +
        _month(local.month) +
        ' ' +
        local.year.toString() +
        ' ' +
        local.hour.toString().padLeft(2, '0') +
        ':' +
        local.minute.toString().padLeft(2, '0');
  }

  String _month(int month) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filtered = devices.where((device) {
      final status = _value(device, 'status');
      final text = <String>[
        _value(device, 'id'),
        _value(device, 'username'),
        _value(device, 'full_name'),
        _value(device, 'company_id'),
        _value(device, 'device_name'),
        _value(device, 'device_type'),
      ].join(' ').toLowerCase();
      return (statusFilter == 'All' || status == statusFilter) &&
          (query.isEmpty || text.contains(query));
    }).toList();

    final pending = devices.where((d) => _value(d, 'status') == 'pending').length;
    final approved = devices.where((d) => _value(d, 'status') == 'approved').length;
    final rejected = devices.where((d) => _value(d, 'status') == 'rejected').length;

    return ScreenFrame(
      title: 'Device Authentication',
      subtitle: 'Approve, reject and revoke devices before they can access the WMS.',
      actions: [
        OutlinedButton.icon(
          onPressed: loading ? null : loadDevices,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat('Pending', pending.toString(), Icons.pending_actions_outlined),
              _stat('Approved', approved.toString(), Icons.verified_user_outlined),
              _stat('Rejected', rejected.toString(), Icons.block_outlined),
              _stat('Total Devices', devices.length.toString(), Icons.devices_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search device, user or company',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      DropdownMenuItem(value: 'revoked', child: Text('Revoked')),
                    ],
                    onChanged: (value) =>
                        setState(() => statusFilter = value ?? 'All'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const WmsTableSkeleton(rows: 5, columns: 6)
          else if (errorMessage != null)
            WmsErrorState(message: errorMessage!, onRetry: loadDevices)
          else if (filtered.isEmpty)
            const WmsEmptyState(
              title: 'No devices found',
              message: 'No devices match the selected filter.',
            )
          else
            _deviceTable(filtered),
        ],
      ),
    );
  }

  Widget _deviceTable(List<Map<String, dynamic>> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: HorizontalTableScroller(
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 62,
          dataRowMaxHeight: 70,
          columnSpacing: 22,
          horizontalMargin: 18,
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
          columns: const [
            DataColumn(
              columnWidth: FixedColumnWidth(125),
              label: Text('Device ID', style: _headerStyle),
            ),
            DataColumn(
              columnWidth: FixedColumnWidth(150),
              label: Text('User', style: _headerStyle),
            ),
            DataColumn(
              columnWidth: FixedColumnWidth(160),
              label: Text('Device', style: _headerStyle),
            ),
            DataColumn(
              columnWidth: FixedColumnWidth(170),
              label: Text('Last Seen', style: _headerStyle),
            ),
            DataColumn(
              columnWidth: FixedColumnWidth(105),
              label: Text('Status', style: _headerStyle),
            ),
            DataColumn(
              columnWidth: FixedColumnWidth(230),
              label: Text('Actions', style: _headerStyle),
            ),
          ],
          rows: rows.asMap().entries.map((entry) {
            final row = entry.value;
            final id = _value(row, 'id');
            final status = _value(row, 'status');
            final busy = actionDeviceId == id;
            final name = _value(row, 'full_name') == '-'
                ? _value(row, 'username')
                : _value(row, 'full_name');

            return DataRow(
              cells: [
                DataCell(
                  Tooltip(
                    message: id,
                    child: Text(
                      id.length > 12 ? id.substring(0, 12) + '...' : id,
                      style: const TextStyle(
                        color: Color(0xFF26384F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(name, style: _cellStyle)),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_value(row, 'device_name'), style: _cellStyle),
                      Text(
                        _value(row, 'device_type'),
                        style: const TextStyle(
                          color: Color(0xFF708096),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  _date(_value(row, 'last_seen_at')),
                  style: _cellStyle,
                )),
                DataCell(StatusBadge(_capitalize(status))),
                DataCell(
                  busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Wrap(
                          spacing: 6,
                          children: [
                            if (status == 'pending') ...[
                              _actionButton(
                                'Approve',
                                Icons.check_circle_outline,
                                () => updateStatus(row, 'approved'),
                              ),
                              _actionButton(
                                'Reject',
                                Icons.block_outlined,
                                () => updateStatus(row, 'rejected'),
                                danger: true,
                              ),
                            ],
                            if (status == 'approved')
                              _actionButton(
                                'Revoke',
                                Icons.remove_circle_outline,
                                () => updateStatus(row, 'revoked'),
                                danger: true,
                              ),
                            if (status == 'rejected' || status == 'revoked')
                              _actionButton(
                                'Approve',
                                Icons.check_circle_outline,
                                () => updateStatus(row, 'approved'),
                              ),
                          ],
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red.shade700 : wmsBlue,
        side: BorderSide(
          color: danger ? Colors.red.shade200 : const Color(0xFFB8D2F6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty || value == '-') return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _stat(String title, String value, IconData icon) {
    return Card(
      child: SizedBox(
        width: 190,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28, color: wmsBlue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: Color(0xFF43546A),
  fontSize: 11,
  fontWeight: FontWeight.w800,
);

const _cellStyle = TextStyle(
  color: Color(0xFF26384F),
  fontSize: 11,
  fontWeight: FontWeight.w500,
);
