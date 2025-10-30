import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/admin_repository.dart';

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
      .toUpperCase();
}

class AdminVerificationDetailScreen extends StatelessWidget {
  final String? tutorId;
  final bool embedded;

  const AdminVerificationDetailScreen({
    super.key,
    this.tutorId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tid = tutorId ?? args?['tutorId'] as String?;

    if (tid == null) {
      return Scaffold(
        appBar: embedded
            ? null
            : AppBar(title: const Text('Tutor Verification')),
        body: const Center(child: Text('No tutor selected')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc('verificationRequests/$tid').get(),
      builder: (context, reqSnap) {
        if (!reqSnap.hasData) {
          return Scaffold(
            appBar: embedded
                ? null
                : AppBar(title: const Text('Tutor Verification')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final reqData = reqSnap.data?.data() as Map<String, dynamic>?;
        final status = reqData?['status'] ?? '';
        final files = reqData?['files'] as Map<String, dynamic>?;
        final submittedAt = reqData?['submittedAt'] as Timestamp?;
        final reviewedAt = reqData?['reviewedAt'] as Timestamp?;
        final reviewerId = reqData?['reviewerId'] as String?;

        return FutureBuilder<Map<String, dynamic>>(
          future: AdminRepo().resolveTutorMeta(tid, reqData ?? {}),
          builder: (context, metaSnap) {
            final meta = metaSnap.data ?? {};
            final userName = meta['name'] ?? tid;
            final userEmail = meta['email'] ?? '';

            return Scaffold(
              appBar: embedded
                  ? null
                  : AppBar(title: const Text('Tutor Verification')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          child: Text(
                            _initials(userName),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              if (userEmail.isNotEmpty)
                                Text(
                                  userEmail,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submitted Documents:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (files == null || files.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'This submission has no files yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else ...[
                              _buildDocumentTile(
                                icon: Icons.badge,
                                title: 'IC / MyKad',
                                url: files['icUrl'] as String?,
                              ),
                              _buildDocumentTile(
                                icon: Icons.school,
                                title: 'Education Certificate',
                                url: files['eduCertUrl'] as String?,
                              ),
                              _buildDocumentTile(
                                icon: Icons.account_balance,
                                title: 'Bank Statement',
                                url: files['bankStmtUrl'] as String?,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _approve(context, tid),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reject(context, tid),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (submittedAt != null)
                      Text(
                        'Submitted: ${submittedAt.toDate()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (reviewedAt != null)
                      Text(
                        'Reviewed: ${reviewedAt.toDate()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (reviewerId != null)
                      Text(
                        'Reviewer: $reviewerId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentTile({
    required IconData icon,
    required String title,
    String? url,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: url != null
          ? OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View'),
            )
          : Text('Not uploaded', style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Future<void> _approve(BuildContext context, String tid) async {
    try {
      await AdminRepo().approveTutor(tid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutor approved successfully')),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reject(BuildContext context, String tid) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    try {
      await AdminRepo().rejectTutor(tid, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tutor rejected')));
        Navigator.pop(context, true);
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
