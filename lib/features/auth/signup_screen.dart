import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  String role = 'student';
  bool loading = false;
  final _auth = AuthService();
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: pass,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          const Text('Choose role (demo):'),
          DropdownButton<String>(
            value: role,
            items: const [
              DropdownMenuItem(value: 'student', child: Text('Student')),
              DropdownMenuItem(value: 'tutor', child: Text('Tutor')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => setState(() => role = v ?? 'student'),
          ),
          const SizedBox(height: 12),
          loading
              ? const CircularProgressIndicator()
              : FilledButton(
                  onPressed: () async {
                    setState(() => loading = true);
                    await _auth.signUp(
                      email.text.trim(),
                      pass.text.trim(),
                      displayName: name.text.trim(),
                      role: role,
                    );
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(c, Routes.roleGate);
                  },
                  child: const Text('Create Account'),
                ),
        ],
      ),
    );
  }
}
