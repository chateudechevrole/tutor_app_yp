import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<void> _backfillEmails() async {
    final reqSnap = await FirebaseFirestore.instance
        .collection('verificationRequests')
        .get();
    for (final doc in reqSnap.docs) {
      final data = doc.data();
      final uid = doc.id;
      final tutorEmail = data['tutorEmail'];
      final tutorName = data['tutorName'];
      if (tutorEmail != null || tutorName != null) {
        await FirebaseFirestore.instance.doc('users/$uid').set({
          if (tutorEmail != null) 'email': tutorEmail,
          if (tutorName != null) 'displayName': tutorName,
        }, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Backfill emails from verificationRequests',
              onPressed: () async {
                try {
                  await _backfillEmails();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backfill completed')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('displayName')
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Action')),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final name = data?['displayName'] ?? 'Unknown';
                  final role = data?['role'] ?? 'student';

                  return DataRow(
                    cells: [
                      DataCell(Text(name)),
                      DataCell(_buildRolePill(role)),
                      DataCell(
                        TextButton(
                          onPressed: () =>
                              _showUserDetails(context, doc.id, data),
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRolePill(String role) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.red;
        break;
      case 'tutor':
        color = Colors.blue;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showUserDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic>? data,
  ) {
    final currentRole = data?['role'] ?? 'student';
    String selectedRole = currentRole;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Name: ${data?['displayName'] ?? 'Unknown'}'),
              Text('Email: ${data?['email'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              if (currentRole != 'admin') ...[
                const Text('Change Role:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'tutor', child: Text('Tutor')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: selectedRole != currentRole
                      ? () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set({
                                'role': selectedRole,
                              }, SetOptions(merge: true));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Role updated')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
