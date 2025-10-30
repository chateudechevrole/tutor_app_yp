import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_routes.dart';
import '../tutor/tutor_login_screen.dart';
import '../tutor/shell/tutor_shell.dart';
import '../tutor/tutor_waiting_screen.dart';
import '../tutor/verify_upload_screen.dart';

class TutorGate extends StatefulWidget {
  final Widget child;
  const TutorGate({super.key, required this.child});

  @override
  State<TutorGate> createState() => _TutorGateState();
}

class _TutorGateState extends State<TutorGate> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await _checkAndNavigate();
    });
  }

  void _nav(VoidCallback go) {
    if (_navigated || !mounted || !context.mounted) return;
    _navigated = true;
    go();
  }

  Future<void> _checkAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _nav(
        () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TutorLoginScreen()),
          (r) => false,
        ),
      );
      return;
    }

    final uid = user.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data();
    final role = userData?['role'] ?? '';
    final tutorVerified = userData?['tutorVerified'] ?? false;

    if (!context.mounted) return;

    if (role != 'tutor') {
      return;
    }

    if (tutorVerified == true) {
      _nav(
        () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TutorShell()),
          (r) => false,
        ),
      );
      return;
    }

    final verifyDoc = await FirebaseFirestore.instance
        .collection('verificationRequests')
        .doc(uid)
        .get();
    final status = verifyDoc.data()?['status'] ?? '';

    if (!context.mounted) return;

    if (status == 'pending') {
      _nav(
        () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TutorWaitingScreen()),
          (r) => false,
        ),
      );
      return;
    }

    _nav(
      () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TutorVerifyScreen()),
        (r) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'student';

        if (role != 'tutor') {
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
                      'This account is registered as a Student.',
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
                          Routes.studentShell,
                        );
                      },
                      child: const Text('Open Student app'),
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
  }
}
