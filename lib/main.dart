import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KopersayWmsApp());
}

class KopersayWmsApp extends StatelessWidget {
  const KopersayWmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopersay WMS',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4FAFD),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B8FBD)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD7E7ED)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
