import 'dart:convert';

import 'package:flutter/material.dart';

import '../assets/kopersay_logo_data.dart';
import '../models/app_role.dart';
import '../services/auth_service.dart';
import 'wms_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool loading = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password are required.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final session = await AuthService.instance.login(
        username: username.text.trim(),
        password: password.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WmsShell(role: appRoleFromBackend(session.role))),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'DEVICE_REQUIRED' || error.code == 'DEVICE_NOT_APPROVED') {
        _showMessage(error.message);
      } else if (error.code == 'INVALID_CREDENTIALS') {
        _showMessage('Invalid username or password.');
      } else {
        try {
          await AuthService.instance.enrollCurrentBrowser(
            username: username.text.trim(),
            password: password.text,
          );
          if (!mounted) return;
          _showMessage('This browser is waiting for Master Admin device approval. After approval, login again.');
        } on AuthException catch (enrollmentError) {
          if (!mounted) return;
          _showMessage(enrollmentError.message);
        }
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to connect to the WMS server. Please check the API and try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _logo({double size = 150}) {
    return Image.memory(
      base64Decode(kopersayLogoBase64),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) return _mobileLogin();
            return Row(
              children: [
                Expanded(flex: 5, child: _brandingPanel()),
                Expanded(flex: 4, child: _loginPanel()),
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
          colors: [Color(0xFFEAF5FF), Color(0xFFDCEEFF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 42),
        child: Column(
          children: [
            Center(child: _logo(size: 190)),
            const Spacer(),
            const Text(
              'Warehouse Management System',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF17345E), fontSize: 25, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Inventory • Inward • Outward • Dispatch • Reports',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF55708F), fontSize: 14),
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

  Widget _feature(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1769D5), size: 27),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38516E), fontSize: 11, fontWeight: FontWeight.w600)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE3EAF2))),
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
                        items: const [DropdownMenuItem(value: 'English', child: Text('English'))],
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: _logo(size: 110)),
                  const SizedBox(height: 12),
                  const Text('Welcome Back!', style: TextStyle(color: Color(0xFF10284A), fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue to KOPERSAY WMS', style: TextStyle(color: Color(0xFF718198), fontSize: 15)),
                  const SizedBox(height: 28),
                  _label('Username'),
                  const SizedBox(height: 8),
                  TextField(controller: username, decoration: _inputDecoration(hint: 'Enter username', icon: Icons.person_outline)),
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
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(value: rememberMe, onChanged: (value) => setState(() => rememberMe = value ?? false)),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: loading ? null : login,
                      icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_open_outlined),
                      label: Text(loading ? 'Signing in...' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Your portal is selected automatically from your account role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8492A6), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Center(
                    child: Text('© 2026 KOPERSAY TECHNOLOGIES. All rights reserved.', style: TextStyle(color: Color(0xFF8B98A9), fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Color(0xFF182C47), fontWeight: FontWeight.w700, fontSize: 14));

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF65758A)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD5DEE9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD5DEE9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1769D5), width: 1.5)),
    );
  }

  Widget _mobileLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [const SizedBox(height: 14), _logo(size: 150), const SizedBox(height: 18), _loginPanel()]),
    );
  }
}
