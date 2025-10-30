import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_routes.dart';
import '../../theme/student_theme.dart';

class TutorDetailScreen extends StatelessWidget {
  final String tutorId;

  const TutorDetailScreen({super.key, required this.tutorId});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: studentTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tutor Profile')),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .doc('tutorProfiles/$tutorId')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('Tutor not found'));
            }

            return _buildContent(context, data);
          },
        ),
        bottomNavigationBar: _buildBookNowButton(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final displayName = data['displayName'] ?? data['email'] ?? 'Tutor';
    final photoUrl = data['photoUrl'] as String?;
    final subjects = List<String>.from(data['subjects'] ?? []);
    final grades = List<String>.from(data['grades'] ?? []);
    final languages = List<String>.from(data['languages'] ?? []);
    final intro = data['intro'] as String?;
    final teachingStyle = data['teachingStyle'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar and Name
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: kStudentDeep.withValues(alpha: 0.1),
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(Icons.person, size: 60, color: kStudentDeep)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: subjects
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: kStudentDeep.withValues(alpha: 0.1),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Grade Levels
        if (grades.isNotEmpty) ...[
          const Text(
            'Grade Levels',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grades
                .map(
                  (g) => Chip(
                    label: Text(g),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Introduction
        _buildSection('Introduction', intro ?? 'No introduction provided yet.'),

        // Teaching Style
        _buildSection(
          'Teaching Style',
          teachingStyle ?? 'No teaching style described yet.',
        ),

        // Languages Spoken
        if (languages.isNotEmpty) ...[
          const Text(
            'Languages Spoken',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages
                .map(
                  (l) => Chip(
                    label: Text(l),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Reviews
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReviewsList(),

        const SizedBox(height: 80), // Space for bottom button
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tutorProfiles/$tutorId/reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading reviews: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No reviews yet. Be the first to book this tutor!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] ?? 0).toDouble();
            final text = data['text'] ?? '';
            final byName = data['byName'] ?? 'Anonymous';
            final createdAt = data['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          byName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(text),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildBookNowButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.bookingConfirm,
              arguments: tutorId,
            );
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: kStudentDeep,
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
