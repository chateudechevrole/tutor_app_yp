import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/tutor_theme.dart';
import '../../../core/app_routes.dart';
import '../../../data/repositories/tutor_repository.dart';

class TutorAccountSettingsScreen extends StatefulWidget {
  const TutorAccountSettingsScreen({super.key});

  @override
  State<TutorAccountSettingsScreen> createState() =>
      _TutorAccountSettingsScreenState();
}

class _TutorAccountSettingsScreenState
    extends State<TutorAccountSettingsScreen> {
  bool _acceptingBookings = true;
  bool _notifyEnabled = true;
  bool _loadingSettings = true;
  final _tutorRepo = TutorRepo();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.doc('users/$uid').get();
    final data = doc.data();

    if (data != null && mounted) {
      setState(() {
        _acceptingBookings = data['acceptingBookings'] ?? true;
        _notifyEnabled = data['notifyEnabled'] ?? true;
        _loadingSettings = false;
      });
    }
  }

  Future<void> _toggleAcceptingBookings(bool value) async {
    setState(() => _acceptingBookings = value);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'acceptingBookings': value,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        setState(() => _acceptingBookings = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifyEnabled = value);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'notifyEnabled': value,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        setState(() => _notifyEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTermsAndPrivacy() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'By using QuickTutor, you agree to provide quality tutoring services, maintain professional conduct, and respect student privacy.',
              ),
              SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'We collect and store your profile information, session data, and payment details securely. Your data is used solely for platform operations and is never shared with third parties without consent.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Account deletion feature is coming soon. Please contact support if you need to delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await _tutorRepo.setOnline(uid, false);
              }
              await FirebaseAuth.instance.signOut();
              if (this.context.mounted) {
                Navigator.of(this.context).pushNamedAndRemoveUntil(
                  Routes.login,
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Setting'),
        ),
        body: _loadingSettings
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const SizedBox(height: 8),
                  
                  // Account Role (read-only)
                  const ListTile(
                    leading: Icon(Icons.badge),
                    title: Text(
                      'Account Role',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      'Tutor',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const Divider(),
                  
                  // Availability
                  SwitchListTile(
                    value: _acceptingBookings,
                    onChanged: _toggleAcceptingBookings,
                    title: const Text(
                      'Accepting Bookings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _acceptingBookings
                          ? 'Students can book you'
                          : 'You are hidden from search',
                      style: TextStyle(
                        color: _acceptingBookings ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    activeThumbColor: kPrimary,
                    secondary: Icon(
                      Icons.calendar_today,
                      color: _acceptingBookings ? kPrimary : Colors.grey,
                    ),
                  ),
                  const Divider(),

                  // Notifications
                  SwitchListTile(
                    value: _notifyEnabled,
                    onChanged: _toggleNotifications,
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Receive booking and message alerts',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: kPrimary,
                    secondary: Icon(
                      Icons.notifications,
                      color: _notifyEnabled ? kPrimary : Colors.grey,
                    ),
                  ),
                  const Divider(),

                  // Terms & Privacy
                  ListTile(
                    leading: const Icon(Icons.description, color: kPrimary),
                    title: const Text(
                      'Terms & Privacy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showTermsAndPrivacy,
                  ),
                  const Divider(),

                  // Delete Account
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: _confirmDeleteAccount,
                  ),
                  const Divider(),

                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: kPrimary),
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _logout,
                  ),
                ],
              ),
      ),
    );
  }
}
