import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login/admin_login_screen.dart';
import '../debug/admin_debug.dart';

class AdminGate extends StatefulWidget {
  final Widget child;
  const AdminGate({super.key, required this.child});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AdminLoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, docSnapshot) {
            if (!docSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = docSnapshot.data?.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? '';

            if (role != 'admin') {
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
                          'This account is not an admin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                        if (kDebugMode)
                          TextButton(
                            onPressed: () async {
                              await debugPromoteToAdmin(context);
                              if (context.mounted) setState(() {});
                            },
                            child: const Text('Promote this account (debug)'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return widget.child;
          },
        );
      },
    );
  }
}
