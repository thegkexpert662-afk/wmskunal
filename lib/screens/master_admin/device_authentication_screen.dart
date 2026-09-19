import 'package:flutter/material.dart';
import '../common_widgets.dart';

class DeviceAuthenticationScreen extends StatefulWidget {
  const DeviceAuthenticationScreen({super.key});

  @override
  State<DeviceAuthenticationScreen> createState() =>
      _DeviceAuthenticationScreenState();
}

class _DeviceAuthenticationScreenState
    extends State<DeviceAuthenticationScreen> {
  String statusFilter = 'All';
  final TextEditingController search = TextEditingController();

  final List<List<String>> devices = const [
    ['DEV-1001', 'Admin User', 'Company A', 'Windows / Chrome', '19 Sep 2026', 'Approved'],
    ['DEV-1002', 'Manager A', 'Company A', 'Windows / Edge', '19 Sep 2026', 'Pending'],
    ['DEV-1003', 'Client A1', 'Client Portal', 'Android / Chrome', '18 Sep 2026', 'Approved'],
    ['DEV-1004', 'Unknown Device', 'Unassigned', 'Windows / Chrome', '18 Sep 2026', 'Rejected'],
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = devices.where((row) {
      final q = search.text.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          row.any((value) => value.toLowerCase().contains(q));
      final matchesStatus =
          statusFilter == 'All' || row[5] == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return ScreenFrame(
      title: 'Device Authentication',
      subtitle:
          'Approve, reject and revoke devices before they can access the WMS.',
      actions: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Register Device'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat('Pending', '1', Icons.pending_actions_outlined),
              _stat('Approved', '2', Icons.verified_user_outlined),
              _stat('Rejected', '1', Icons.block_outlined),
              _stat('Total Devices', '4', Icons.devices_outlined),
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
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) =>
                        setState(() => statusFilter = value ?? 'All'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DataTableCard(
            headers: const [
              'Device ID',
              'User',
              'Company',
              'Device',
              'Last Seen',
              'Status',
            ],
            rows: filtered,
            statusColumns: const [5],
          ),
        ],
      ),
    );
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
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
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
