import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_routes.dart';

enum UserRole { student, tutor }

/// Screen shown when a user has authenticated but has no role set.
/// This can happen for legacy users or if role assignment failed during signup.
class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({super.key});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  UserRole selectedRole = UserRole.student;
  bool loading = false;

  Future<void> _saveRole() async {
    setState(() => loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      // Check if user already has a role set
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final existingRole = userDoc.data()?['role'] as String?;
      
      if (existingRole != null && existingRole.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your role is already set. Please contact admin to change it.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final roleString = selectedRole == UserRole.student ? 'student' : 'tutor';

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'role': roleString},
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // Navigate to role gate which will route to appropriate shell
      Navigator.pushReplacementNamed(context, Routes.roleGate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save role: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to QuickTutor!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select your role to continue:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 12),
            const Text(
              'You can change this later in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            loading
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _saveRole,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: Text('Continue'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
