import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tutor_theme.dart';
import 'shell/tutor_shell.dart';
import 'verify_upload_screen.dart';

class TutorWaitingScreen extends StatefulWidget {
  const TutorWaitingScreen({super.key});

  @override
  State<TutorWaitingScreen> createState() => _TutorWaitingScreenState();
}

class _TutorWaitingScreenState extends State<TutorWaitingScreen> {
  bool _navigated = false;

  void _nav(VoidCallback go) {
    if (_navigated || !context.mounted) return;
    _navigated = true;
    go();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: kBg,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('verificationRequests')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending';

          if (status == 'approved') {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseFirestore.instance.collection('users').doc(uid).set(
                {'tutorVerified': true},
                SetOptions(merge: true),
              );
              if (!context.mounted) return;
              _nav(
                () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const TutorShell()),
                  (r) => false,
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (status == 'rejected') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verification Rejected',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please resubmit your documents.',
                      style: TextStyle(
                        fontSize: 16,
                        color: kPrimary.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        if (!context.mounted) return;
                        _nav(
                          () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const TutorVerifyScreen(),
                            ),
                            (r) => false,
                          ),
                        );
                      },
                      child: const Text('Resubmit Documents'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty, size: 80, color: kPrimary),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Profile Is Being Verified',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We will review your documents within 1-2 business days.',
                    style: TextStyle(
                      fontSize: 16,
                      color: kPrimary.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
