import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../core/app_routes.dart';
import 'admin_verification_detail_screen.dart';

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
      .toUpperCase();
}

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final _adminRepo = AdminRepo();
  String? _selectedTutorId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedDoc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Verification')),
      body: Row(
        children: [
          SizedBox(
            width: 360,
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _adminRepo.pendingVerifications(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text("Couldn't load…"),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs
                    ..sort((a, b) {
                      final aTime = a.data()['submittedAt'] ?? Timestamp(0, 0);
                      final bTime = b.data()['submittedAt'] ?? Timestamp(0, 0);
                      return (bTime as Timestamp).compareTo(aTime as Timestamp);
                    });

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending submissions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final tutorId = doc.id;
                      final data = doc.data();
                      final submittedAt = data['submittedAt'] as Timestamp?;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _adminRepo.resolveTutorMeta(tutorId, data),
                        builder: (context, metaSnap) {
                          final meta = metaSnap.data ?? {};
                          final userName = meta['name'] ?? tutorId;
                          final userEmail = meta['email'];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              selected: _selectedTutorId == tutorId,
                              leading: CircleAvatar(
                                child: Text(_initials(userName)),
                              ),
                              title: Text(userName),
                              subtitle: Text(
                                userEmail ??
                                    (submittedAt != null
                                        ? 'Submitted • ${_formatRelativeTime(submittedAt.toDate())}'
                                        : tutorId.length > 8
                                        ? '${tutorId.substring(0, 6)}…'
                                        : tutorId),
                              ),
                              trailing: const Chip(label: Text('PENDING')),
                              onTap: () async {
                                final isNarrow =
                                    MediaQuery.sizeOf(context).width < 720;
                                if (isNarrow) {
                                  await Navigator.pushNamed(
                                    context,
                                    Routes.adminVerifyDetail,
                                    arguments: {'tutorId': tutorId},
                                  );
                                  // Refresh on return
                                  if (mounted) setState(() {});
                                } else {
                                  setState(() {
                                    _selectedTutorId = tutorId;
                                    _selectedDoc = doc;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _selectedDoc == null || _selectedTutorId == null
                ? const Center(child: Text('Select a tutor to review'))
                : AdminVerificationDetailScreen(
                    tutorId: _selectedTutorId,
                    embedded: true,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
