import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyQueueScreen extends StatelessWidget {
  const VerifyQueueScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final q = FirebaseFirestore.instance
        .collection('verificationRequests')
        .snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Verification Queue')),
      body: StreamBuilder(
        stream: q,
        builder: (ctx, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final id = docs[i].id;
              final d = docs[i].data();
              final status = d['status'] ?? 'pending';
              final files = d['files'] as Map<String, dynamic>?;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Tutor $id'),
                  subtitle: Text('Status: $status'),
                  children: [
                    if (files != null) ...[
                      _buildFileLink(c, 'IC / MyKad', files['icUrl']),
                      _buildFileLink(
                        c,
                        'Education Certificate',
                        files['eduCertUrl'],
                      ),
                      _buildFileLink(c, 'Bank Statement', files['bankStmtUrl']),
                      const Divider(),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .doc('users/$id')
                                  .set({
                                    'role': 'tutor',
                                    'tutorVerified': true,
                                  }, SetOptions(merge: true));
                              await FirebaseFirestore.instance
                                  .doc('tutorProfiles/$id')
                                  .set({
                                    'verified': true,
                                  }, SetOptions(merge: true));
                              await FirebaseFirestore.instance
                                  .doc('verificationRequests/$id')
                                  .set({
                                    'status': 'approved',
                                    'reviewedAt': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));
                            },
                            child: const Text('Approve'),
                          ),
                          FilledButton.tonal(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .doc('verificationRequests/$id')
                                  .set({
                                    'status': 'rejected',
                                  }, SetOptions(merge: true));
                            },
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFileLink(BuildContext c, String label, String? url) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: url != null
          ? TextButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: const Text('View'),
            )
          : const Text('Not uploaded', style: TextStyle(color: Colors.grey)),
    );
  }
}
