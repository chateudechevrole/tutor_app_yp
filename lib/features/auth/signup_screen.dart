import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/app_routes.dart';

enum UserRole { student, tutor }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  UserRole selectedRole = UserRole.student;
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
          const SizedBox(height: 12),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'I am a:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SegmentedButton<UserRole>(
            segments: const [
              ButtonSegment<UserRole>(
                value: UserRole.student,
                label: Text('Student'),
                icon: Icon(Icons.school),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.tutor,
                label: Text('Tutor'),
                icon: Icon(Icons.person),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: (Set<UserRole> newSelection) {
              setState(() {
                selectedRole = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'You can change this later in Settings.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          loading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty ||
                        email.text.trim().isEmpty ||
                        pass.text.trim().isEmpty) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                        ),
                      );
                      return;
                    }
                    setState(() => loading = true);
                    try {
                      await _auth.signUp(
                        email.text.trim(),
                        pass.text.trim(),
                        displayName: name.text.trim(),
                        role: selectedRole == UserRole.student ? 'student' : 'tutor',
                      );
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(c, Routes.roleGate);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(
                          SnackBar(content: Text('Sign up failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
                  child: const Text('Create Account'),
                ),
        ],
      ),
    );
  }
}
