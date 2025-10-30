import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_routes.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickTutor Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots()
            : null,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final displayName = data?['displayName'] ?? 'Admin';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.admin_panel_settings, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              _buildMenuItem(
                context,
                icon: Icons.account_circle,
                title: 'Account Settings',
                onTap: () => Navigator.pushNamed(context, Routes.adminAccount),
              ),
              _buildMenuItem(
                context,
                icon: Icons.people,
                title: 'User Management',
                onTap: () => Navigator.pushNamed(context, Routes.adminUsers),
              ),
              _buildMenuItem(
                context,
                icon: Icons.verified_user,
                title: 'Tutor Verification',
                onTap: () => Navigator.pushNamed(context, Routes.adminVerify),
              ),
              _buildMenuItem(
                context,
                icon: Icons.book_online,
                title: 'Booking Records',
                onTap: () => Navigator.pushNamed(context, Routes.adminBookings),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
