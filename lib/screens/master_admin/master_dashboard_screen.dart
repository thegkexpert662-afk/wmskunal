import 'package:flutter/material.dart';

class MasterDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const MasterDashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical / System Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF10243E)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Technical administration, company tenants, access control and security.',
            style: TextStyle(color: Color(0xFF718198)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Card(
                title: 'Companies / Admin Management',
                icon: Icons.business_outlined,
                description: 'Create companies, manage status and module access.',
                onTap: () => onNavigate?.call(1),
              ),
              _Card(
                title: 'Users & Roles',
                icon: Icons.manage_accounts_outlined,
                description: 'Create users, assign roles and warehouse access.',
                onTap: () => onNavigate?.call(2),
              ),
              _Card(
                title: 'System Settings',
                icon: Icons.settings_outlined,
                description: 'Application-wide technical configuration.',
                onTap: () => onNavigate?.call(3),
              ),
              _Card(
                title: 'Security / Audit',
                icon: Icons.security_outlined,
                description: 'Security events, access history and audit controls.',
                onTap: () => onNavigate?.call(4),
              ),
              _Card(
                title: 'Technical Support',
                icon: Icons.support_agent_outlined,
                description: 'Resolve technical access and workflow issues.',
                onTap: () => onNavigate?.call(5),
              ),
              _Card(
                title: 'Device Authentication',
                icon: Icons.devices_outlined,
                description: 'Approve and manage registered WMS devices.',
                onTap: () => onNavigate?.call(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const _Card({
    required this.title,
    required this.icon,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE1E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1769D5)),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF182C47),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF718198),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
