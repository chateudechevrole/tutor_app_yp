import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../core/app_routes.dart';
import '../../../theme/student_theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (uid == null) {
      return Scaffold(
        backgroundColor: kStudentBg,
        body: const Center(child: Text('Please sign in.')),
      );
    }

    return Scaffold(
      backgroundColor: kStudentBg,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: kStudentDeep, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kStudentBg,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final displayName = data?['displayName'] ?? 'Student';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: kStudentDeep,
                    foregroundColor: Colors.white,
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: kStudentDeep, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display Name',
                        style: TextStyle(
                          color: kStudentDeep.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: kStudentDeep,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email',
                        style: TextStyle(
                          color: kStudentDeep.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? '',
                        style: TextStyle(color: kStudentDeep, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, Routes.login);
                      }
                    },
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
