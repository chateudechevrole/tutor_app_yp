import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Verify Tutors'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(c, Routes.verifyQueue),
          ),
          const ListTile(
            title: Text('Booking Records (TODO)'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Users Management (TODO)'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
