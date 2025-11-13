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

String _formatFriendlyDate(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  final month = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  return '$day $month ${dt.year} • $hour:$minute $period';
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    case 'pending':
    default:
      return 'Pending Review';
  }
}

String _formatTimestamp(Timestamp? ts) {
  if (ts == null) return 'Not provided';
  return _formatFriendlyDate(ts.toDate());
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
            final statusLabel = _statusLabel(status);
            final statusColor = _statusColor(status);
            final submittedLabel = _formatTimestamp(submittedAt);
            final reviewedLabel = _formatTimestamp(reviewedAt);
            final infoMessage = switch (status.toLowerCase()) {
              'approved' =>
                'Everything looks good. You can let the tutor know their profile is live.',
              'rejected' =>
                'This submission has been declined. Confirm that the rejection notes are clear.',
              _ =>
                'Review the tutor’s documents and confirm the details before approving.',
            };

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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 8),
                              Text(
                                infoMessage,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          label: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
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
                            Text(
                              'Submission Summary',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              icon: Icons.perm_identity,
                              label: 'Tutor ID',
                              value: tid,
                            ),
                            _buildInfoRow(
                              context,
                              icon: Icons.schedule,
                              label: 'Submitted on',
                              value: submittedLabel,
                            ),
                            _buildInfoRow(
                              context,
                              icon: Icons.verified_user,
                              label: 'Current status',
                              value: statusLabel,
                              valueColor: statusColor,
                            ),
                            if (reviewedAt != null)
                              _buildInfoRow(
                                context,
                                icon: Icons.event_available,
                                label: 'Reviewed on',
                                value: reviewedLabel,
                              ),
                            if (reviewerId != null)
                              _buildInfoRow(
                                context,
                                icon: Icons.account_circle,
                                label: 'Reviewed by',
                                value: reviewerId,
                              ),
                          ],
                        ),
                      ),
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
                            Text(
                              'Documents to review',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open each file to confirm the information is clear and matches the tutor’s profile.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            if (files == null || files.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No documents have been uploaded yet. Ask the tutor to resubmit their verification files.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else ...[
                              _buildDocumentTile(
                                context: context,
                                icon: Icons.badge,
                                title: 'Identity Document',
                                description:
                                    'Government-issued ID (MyKad or passport).',
                                url: files['icUrl'] as String?,
                              ),
                              _buildDocumentTile(
                                context: context,
                                icon: Icons.school,
                                title: 'Academic Qualification',
                                description:
                                    'Highest qualification or teaching credential.',
                                url: files['eduCertUrl'] as String?,
                              ),
                              _buildDocumentTile(
                                context: context,
                                icon: Icons.account_balance,
                                title: 'Bank Details',
                                description:
                                    'Statement showing the tutor’s payout account.',
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
    required BuildContext context,
    required IconData icon,
    required String title,
    String? description,
    String? url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: description != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : null,
        trailing: url != null
            ? FilledButton.tonalIcon(
                onPressed: () async {
                  if (_isImageUrl(url)) {
                    _showImagePreview(context, url, title);
                  } else {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(_isPdfUrl(url) ? 'Open PDF' : 'Open Link'),
              )
            : Text(
                'Not uploaded',
                style: TextStyle(color: Colors.red.shade400),
              ),
      ),
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
                  child: InteractiveViewer(child: Image.network(imageUrl)),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
