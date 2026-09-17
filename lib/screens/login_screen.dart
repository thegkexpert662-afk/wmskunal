import 'package:flutter/material.dart';
import 'wms_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool client = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email and password are required.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WmsShell(clientMode: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 850;

          return Row(
            children: [
              if (!compact)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF087FA9),
                          Color(0xFF064F70),
                        ],
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(55),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warehouse_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                          SizedBox(height: 22),
                          Text(
                            'KOPERSAY WMS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Warehouse Management System',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warehouse_rounded,
                                color: Color(0xFF0B8FBD),
                                size: 48,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                client ? 'Client Portal Login' : 'Admin Login',
                                style: const TextStyle(
                                  color: Color(0xFF70858F),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('Admin'),
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('Client'),
                                  ),
                                ],
                                selected: {client},
                                onSelectionChanged: (values) {
                                  setState(() {
                                    client = values.first;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: password,
                                obscureText: obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        obscure = !obscure;
                                      });
                                    },
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: login,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
