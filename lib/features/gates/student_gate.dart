import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_routes.dart';

class StudentGate extends StatelessWidget {
  final Widget child;
  const StudentGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to continue.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'student';

        if (role != 'student') {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'This account is registered as a Tutor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          Routes.tutorDash,
                        );
                      },
                      child: const Text('Open Tutor app'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
