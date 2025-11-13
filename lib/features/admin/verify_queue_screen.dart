import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isImageUrl(String url) {
  final uri = Uri.parse(url);
  final path = uri.path.toLowerCase();
  return path.endsWith('.jpg') || 
         path.endsWith('.jpeg') || 
         path.endsWith('.png') || 
         path.endsWith('.gif') ||
         path.endsWith('.webp');
}

bool _isPdfUrl(String url) {
  final uri = Uri.parse(url);
  return uri.path.toLowerCase().endsWith('.pdf');
}

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
                if (_isImageUrl(url)) {
                  // Show in-app image preview
                  _showImagePreview(c, url, label);
                } else if (_isPdfUrl(url)) {
                  // Open PDF in browser
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } else {
                  // Fallback for unknown types
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: const Text('View'),
            )
          : const Text('Not uploaded', style: TextStyle(color: Colors.grey)),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(title),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(imageUrl),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
