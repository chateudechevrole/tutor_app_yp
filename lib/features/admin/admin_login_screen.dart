import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Admin Login')),
    body: Center(
      child: FilledButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(c, Routes.adminDashboard),
        child: const Text('Enter (Demo)'),
      ),
    ),
  );
}
