import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/tutor_repository.dart';
import '../../core/app_routes.dart';

class TutorSearchScreen extends StatelessWidget {
  const TutorSearchScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final stream = TutorRepo().search();
    return Scaffold(
      appBar: AppBar(title: const Text('Online Tutors')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (ctx, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No tutors online'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              return ListTile(
                title: Text(d['displayName'] ?? 'Tutor'),
                subtitle: Text('Subjects: ${(d['subjects'] ?? []).join(", ")}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(
                  c,
                  Routes.tutorProfile,
                  arguments: docs[i].id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
