import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  final String roleLabel;

  const AdminProfileScreen({super.key, this.roleLabel = 'Administrator'});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE1E8F0))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF10243E))),
            const SizedBox(height: 24),
            const CircleAvatar(radius: 34, backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.person, size: 34, color: Color(0xFF1769D5))),
            const SizedBox(height: 18),
            const Text('User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(roleLabel, style: const TextStyle(color: Color(0xFF718198))),
          ]),
        ),
      ),
    );
  }
}
