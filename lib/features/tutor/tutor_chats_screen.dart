import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/tutor_theme.dart';
import '../../core/app_routes.dart';

class TutorChatsScreen extends StatelessWidget {
  const TutorChatsScreen({super.key});

  @override
  Widget build(BuildContext c) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat Threads')),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: uid)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final threads = snapshot.data!.docs;
            if (threads.isEmpty) {
              return const Center(child: Text('No chat threads yet'));
            }
            return ListView.builder(
              itemCount: threads.length,
              itemBuilder: (_, i) {
                final thread = threads[i];
                final threadId = thread.id;
                final participants = List<String>.from(
                  thread.data()['participants'] ?? [],
                );
                final otherUid = participants.firstWhere(
                  (p) => p != uid,
                  orElse: () => 'Unknown',
                );
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Chat with $otherUid'),
                  subtitle: const Text('Tap to open'),
                  onTap: () => Navigator.pushNamed(
                    c,
                    Routes.tutorChat,
                    arguments: threadId,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
