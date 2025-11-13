import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/tutor_repository.dart';
import '../../data/repositories/tutor_availability_repository.dart';
import '../../core/app_routes.dart';

class TutorSearchScreen extends StatelessWidget {
  const TutorSearchScreen({super.key});

  @override
  Widget build(BuildContext c) {
    final stream = TutorRepo().search();
    final availabilityRepo = TutorAvailabilityRepository();

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

          // Filter out unavailable tutors
          return FutureBuilder<Map<String, bool>>(
            future: availabilityRepo.checkMultipleTutors(
              docs.map((doc) => doc.id).toList(),
            ),
            builder: (context, availSnapshot) {
              if (!availSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final availableDocs = docs.where((doc) {
                return availSnapshot.data![doc.id] == true;
              }).toList();

              if (availableDocs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No available tutors',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All tutors are currently busy or offline',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: availableDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = availableDocs[i].data();
                  return ListTile(
                    title: Text(d['displayName'] ?? 'Tutor'),
                    subtitle: Text('Subjects: ${(d['subjects'] ?? []).join(", ")}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(
                      c,
                      Routes.tutorProfile,
                      arguments: availableDocs[i].id,
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
