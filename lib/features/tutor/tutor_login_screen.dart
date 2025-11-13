import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../core/app_routes.dart';
import '../../theme/tutor_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// @deprecated This screen is deprecated. Use the shared LoginScreen instead.
/// This file will be removed in a future version.
/// The app now uses role-based routing from a single login screen.
class TutorLoginScreen extends StatefulWidget {
  const TutorLoginScreen({super.key});
  @override
  State<TutorLoginScreen> createState() => _TutorLoginScreenState();
}

// TODO: Remove this file after confirming all references are updated to use shared LoginScreen
class _TutorLoginScreenState extends State<TutorLoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  final _auth = AuthService();

  @override
  Widget build(BuildContext c) {
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tutor Login')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              loading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        try {
                          await _auth.signIn(
                            email.text.trim(),
                            pass.text.trim(),
                          );
                          final uid = FirebaseAuth.instance.currentUser!.uid;
                          final userSnap = await FirebaseFirestore.instance
                              .doc('users/$uid')
                              .get();
                          final role = userSnap.data()?['role'] ?? 'student';

                          if (role != 'tutor') {
                            if (!mounted) return;
                            await showDialog(
                              context: c,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Wrong Account Type'),
                                content: const Text(
                                  'This account is not registered as a tutor.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pushReplacementNamed(
                                        c,
                                        Routes.studentShell,
                                      );
                                    },
                                    child: const Text('Go to Student App'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _auth.signOut();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          final tutorVerified =
                              userSnap.data()?['tutorVerified'] ?? false;
                          final verifySnap = await FirebaseFirestore.instance
                              .doc('verificationRequests/$uid')
                              .get();
                          final status = verifySnap.data()?['status'];

                          if (!mounted) return;
                          if (tutorVerified) {
                            Navigator.pushReplacementNamed(c, Routes.tutorDash);
                          } else if (status == 'pending') {
                            Navigator.pushReplacementNamed(
                              c,
                              Routes.tutorWaiting,
                            );
                          } else {
                            Navigator.pushReplacementNamed(
                              c,
                              Routes.tutorVerify,
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(
                              SnackBar(
                                content: Text(e.message ?? 'Login failed'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => loading = false);
                        }
                      },
                      child: const Text('Sign In'),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(c, Routes.signup),
                child: const Text('Create tutor account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
