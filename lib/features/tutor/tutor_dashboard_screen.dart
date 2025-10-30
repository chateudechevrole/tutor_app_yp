import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/tutor_repository.dart';
import '../../core/app_routes.dart';
import '../../theme/tutor_theme.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});
  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  bool online = false;
  bool tutorVerified = false;
  final _repo = TutorRepo();

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance.doc('users/$uid').get();
    final verified = snap.data()?['tutorVerified'] ?? false;
    if (!verified && mounted) {
      Navigator.pushReplacementNamed(context, Routes.tutorVerify);
    } else {
      setState(() => tutorVerified = verified);
    }
  }

  Future<void> _loadOnlineStatus() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .doc('tutorProfiles/$uid')
        .get();
    if (snap.exists && mounted) {
      setState(() => online = snap.data()?['isOnline'] ?? false);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Theme(
      data: tutorTheme,
      child: SafeArea(
        child: Column(
          children: [
            // Online status header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: tutorTheme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  FutureBuilder(
                    future: FirebaseFirestore.instance
                        .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
                        .get(),
                    builder: (ctx, snap) {
                      final name = snap.data?.data()?['displayName'] ?? 'Tutor';
                      return Text(
                        'Hi, $name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  const Text('Online:', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: online,
                    onChanged: (v) async {
                      setState(() => online = v);
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      await _repo.setOnline(uid, v);
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildHomeContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tutorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int sessionsCount = 0;
        double totalEarnings = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'completed') {
              sessionsCount++;
              totalEarnings += (data['price'] ?? 0).toDouble();
            }
          }
        }

        final hasRecords =
            tutorVerified && (sessionsCount > 0 || totalEarnings > 0);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'TUTOR BUILD',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!hasRecords) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Icon(Icons.library_books, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No teaching records yet.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start accepting bookings after verification.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'In this week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Sessions',
                      '$sessionsCount',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Avg Rating', '4.8', Icons.star),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Earnings',
                'RM ${totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
              ),
            ],
            const SizedBox(height: 24),
            _buildMenuItem('Class History', Icons.history, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class History - Coming Soon')),
              );
            }),
            _buildMenuItem('Earnings & Payout', Icons.payment, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Earnings - Coming Soon')),
              );
            }),
            _buildMenuItem('Identity Verification', Icons.verified_user, () {
              Navigator.pushNamed(context, Routes.tutorVerify);
            }),
            _buildMenuItem('Account Setting', Icons.settings, () {
              Navigator.pushNamed(context, Routes.tutorEdit);
            }),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: kPrimary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
