import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../core/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  final _auth = AuthService();
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
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
                      final args = ModalRoute.of(context)?.settings.arguments;
                      final mapArgs =
                          args is Map ? args.cast<String, dynamic>() : null;
                      final targetRole = mapArgs?['targetRole'] as String?;
                      final redirectRoute =
                          mapArgs?['redirectRoute'] as String?;

                      setState(() => loading = true);

                      var errorMessage = '';
                      var success = false;

                      try {
                        await _auth.signIn(email.text.trim(), pass.text.trim());

                        final user = FirebaseAuth.instance.currentUser;
                        if (targetRole != null && user != null) {
                          final userSnap = await FirebaseFirestore.instance
                              .doc('users/${user.uid}')
                              .get();
                          final actualRole =
                              (userSnap.data()?['role'] ?? '').toString();

                          if (actualRole != targetRole) {
                            errorMessage = targetRole == 'tutor'
                                ? 'This account is not registered as a tutor.'
                                : 'This account is not registered as a $targetRole.';
                            await FirebaseAuth.instance.signOut();
                          } else {
                            success = true;
                          }
                        } else {
                          success = true;
                        }
                      } on FirebaseAuthException catch (e) {
                        errorMessage = e.message ?? 'Login failed';
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }

                      if (!mounted) return;

                      if (!success) {
                        if (errorMessage.isNotEmpty) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                        }
                        return;
                      }

                      final navigator = Navigator.of(c);

                      if (navigator.canPop()) {
                        navigator.pop(true);
                      } else {
                        final fallbackRoute = redirectRoute ??
                            (targetRole == 'tutor'
                                ? Routes.tutorShell
                                : targetRole == 'student'
                                    ? Routes.studentShell
                                    : Routes.roleGate);
                        navigator.pushReplacementNamed(fallbackRoute);
                      }
                    },
                    child: const Text('Sign In'),
                  ),
            TextButton(
              onPressed: () => Navigator.pushNamed(c, Routes.signup),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
