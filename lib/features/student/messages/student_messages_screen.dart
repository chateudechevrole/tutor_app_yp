import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/student_theme.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../core/app_routes.dart';

class StudentMessagesScreen extends StatelessWidget {
  const StudentMessagesScreen({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: kStudentBg,
        body: const Center(child: Text('Please sign in.')),
      );
    }

    final chatRepo = ChatRepo();

    return Scaffold(
      backgroundColor: kStudentBg,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(color: kStudentDeep, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kStudentBg,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatRepo.threadsForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: kStudentDeep.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Couldn\'t load messages.',
                    style: TextStyle(
                      color: kStudentDeep,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull to retry.',
                    style: TextStyle(
                      color: kStudentDeep.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading messages...',
                    style: TextStyle(
                      color: kStudentDeep.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: kStudentDeep.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet.',
                    style: TextStyle(
                      color: kStudentDeep,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a chat with a tutor to see it here.',
                    style: TextStyle(
                      color: kStudentDeep.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final threadId = docs[index].id;
              final members =
                  (data['members'] as List<dynamic>?)?.cast<String>() ?? [];
              final otherUid = members.firstWhere(
                (m) => m != uid,
                orElse: () => '',
              );
              final lastMessage = data['lastMessage'] ?? '';
              final updatedAt = data['updatedAt'] as Timestamp?;
              final timeStr = _formatTime(updatedAt);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnapshot) {
                  String otherName = 'User';
                  if (userSnapshot.hasData) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    otherName = userData?['displayName'] ?? 'User';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: kStudentDeep, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: kStudentDeep,
                        foregroundColor: Colors.white,
                        child: Text(
                          otherName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(
                        otherName,
                        style: TextStyle(
                          color: kStudentDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: lastMessage.isNotEmpty
                          ? Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: kStudentDeep.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            )
                          : null,
                      trailing: Text(
                        timeStr,
                        style: TextStyle(
                          color: kStudentDeep.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.studentChat,
                          arguments: threadId,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
