import 'package:flutter/material.dart';

import 'wms_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isClient = false;
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username and password are required.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WmsShell(clientMode: isClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 900;

            if (compact) {
              return _mobileLogin();
            }

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _brandingPanel(),
                ),
                Expanded(
                  flex: 4,
                  child: _loginPanel(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _brandingPanel() {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF5FF),
            Color(0xFFDCEEFF),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kopersayBrand(large: true),
            const Spacer(),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.all(34),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warehouse_rounded,
                      size: 150,
                      color: Color(0xFF1769D5),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Warehouse Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF17345E),
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Inventory • Inward • Outward • Dispatch • Reports',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF55708F),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _feature(Icons.inventory_2_outlined, 'Inventory'),
                _feature(Icons.local_shipping_outlined, 'Inward & Outward'),
                _feature(Icons.bar_chart_outlined, 'Real-time Reports'),
                _feature(Icons.security_outlined, 'Secure Access'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kopersayBrand({bool large = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 58 : 48,
          height: large ? 58 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0B5FE8), Color(0xFF10C6E8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B5FE8).withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.all_inclusive_rounded,
            color: Colors.white,
            size: large ? 36 : 30,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KOPERSAY',
              style: TextStyle(
                color: const Color(0xFF123F8A),
                fontSize: large ? 30 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'TECHNOLOGIES',
              style: TextStyle(
                color: const Color(0xFF159FD4),
                fontSize: large ? 11 : 9,
                fontWeight: FontWeight.w700,
                letterSpacing: large ? 3.0 : 2.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _feature(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1769D5), size: 27),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF38516E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE3EAF2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'English',
                        items: const [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _kopersayBrand(),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back!',
                    style: const TextStyle(
                      color: Color(0xFF10284A),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isClient
                        ? 'Sign in to continue to your client portal'
                        : 'Sign in to continue to your admin / staff account',
                    style: const TextStyle(
                      color: Color(0xFF718198),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _roleSelector(),
                  const SizedBox(height: 28),
                  _label('Username'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: username,
                    decoration: _inputDecoration(
                      hint: 'Enter username',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    decoration: _inputDecoration(
                      hint: 'Enter password',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: login,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: Text(isClient ? 'Login as Client' : 'Login as Admin / Staff'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      isClient
                          ? 'Client access is restricted to your company data.'
                          : 'Admin / Staff access is controlled by assigned roles.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8492A6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Center(
                    child: Text(
                      '© 2026 KOPERSAY TECHNOLOGIES. All rights reserved.',
                      style: TextStyle(
                        color: Color(0xFF8B98A9),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _roleButton(false, 'Admin / Staff', Icons.admin_panel_settings_outlined)),
          Expanded(child: _roleButton(true, 'Client', Icons.business_outlined)),
        ],
      ),
    );
  }

  Widget _roleButton(bool client, String label, IconData icon) {
    final bool selected = isClient == client;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          isClient = client;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xFF1264D8)
                  : const Color(0xFF6F8096),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF123F8A)
                      : const Color(0xFF65758A),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF182C47),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF65758A)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DEE9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DEE9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1769D5), width: 1.5),
      ),
    );
  }

  Widget _mobileLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 14),
          _kopersayBrand(large: true),
          const SizedBox(height: 26),
          _loginPanel(),
        ],
      ),
    );
  }
}
