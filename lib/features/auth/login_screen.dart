import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      appBar: AppBar(title: const Text('Login')),
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
                      setState(() => loading = true);
                      try {
                        await _auth.signIn(email.text.trim(), pass.text.trim());
                        if (mounted) {
                          Navigator.pushReplacementNamed(c, Routes.roleGate);
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
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
