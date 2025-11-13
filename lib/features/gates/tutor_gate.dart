import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_routes.dart';
import '../tutor/tutor_waiting_screen.dart';
import '../tutor/verify_upload_screen.dart';
import '../../data/repositories/tutor_repository.dart';

class TutorGate extends StatelessWidget {
  final Widget child;
  const TutorGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show loading while checking auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        
        // No user - redirect to login
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to QuickTutor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please sign in to continue.'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.login,
                        arguments: const {
                          'targetRole': 'tutor',
                        },
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        // User exists - check role
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            // Show loading while fetching user data
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final role = userData?['role'] ?? '';

            // Not a tutor - sign out and redirect to login
            if (role != 'tutor') {
              // Schedule sign out after build
              Future.microtask(() async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await TutorRepo().setOnline(uid, false);
                }
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.login,
                    arguments: const {
                      'targetRole': 'tutor',
                    },
                  );
                }
              });
              
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 80, color: Colors.red),
                        SizedBox(height: 24),
                        Text(
                          'Access Denied',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This account does not have tutor access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Signing out...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              );
            }

            // User is a tutor - check verification status
            final tutorVerified = userData?['tutorVerified'] ?? false;

            if (tutorVerified == true) {
              // Verified tutor - show main shell
              return child;
            }

            // Not verified - check verification request status
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('verificationRequests')
                  .doc(user.uid)
                  .get(),
              builder: (context, verifySnapshot) {
                if (!verifySnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final verifyData = verifySnapshot.data?.data() as Map<String, dynamic>?;
                final status = verifyData?['status'] ?? '';

                if (status == 'pending') {
                  // Verification pending
                  return const TutorWaitingScreen();
                }

                // No verification request - show upload screen
                return const TutorVerifyScreen();
              },
            );
          },
        );
      },
    );
  }
}
