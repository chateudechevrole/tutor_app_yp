import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_paths.dart';
import '../../core/app_routes.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext c) {
    final tutorId = ModalRoute.of(c)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.doc(FP.tutorProfiles(tutorId)).get(),
        builder: (ctx, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = s.data!.data() ?? {};
          final photoUrl = d['photoUrl'] as String?;
          final hasNetworkPhoto = photoUrl != null &&
              photoUrl.isNotEmpty &&
              !photoUrl.startsWith('file://');
          final displayName = d['displayName'] as String? ?? 'Tutor';
          final email = d['email'] as String? ?? '';
          final intro = d['intro'] as String? ?? 'No introduction provided.';
          final teachingStyle = d['teachingStyle'] as String? ?? '';
          final experience = d['experience'] as String? ?? '';
          final education = d['education'] as String? ?? '';
          final avgRating = (d['avgRating'] ?? 4.8) as num;
          final languages = List<String>.from(d['languages'] ?? []);
          final grades = List<String>.from(d['grades'] ?? []);
          final subjects = List<String>.from(d['subjects'] ?? []);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section with avatar and basic info
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(c).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(c).colorScheme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            hasNetworkPhoto ? NetworkImage(photoUrl) : null,
                        child: !hasNetworkPhoto
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Display Name
                      Text(
                        displayName,
                        style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Email
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],

                      // Rating
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: Theme.of(c).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content sections
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subjects
                      if (subjects.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Subjects'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subjects
                              .map(
                                (subject) => Chip(
                                  label: Text(subject),
                                  backgroundColor: Theme.of(
                                    c,
                                  ).colorScheme.primaryContainer,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Grade Levels
                      if (grades.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Grade Levels'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: grades
                              .map(
                                (grade) => Chip(
                                  label: Text(grade),
                                  backgroundColor: Theme.of(
                                    c,
                                  ).colorScheme.secondaryContainer,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Languages
                      if (languages.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Languages'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: languages
                              .map(
                                (lang) => Chip(
                                  label: Text(lang),
                                  avatar: const Icon(Icons.language, size: 16),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Introduction
                      if (intro.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Introduction'),
                        const SizedBox(height: 8),
                        Text(intro, style: Theme.of(c).textTheme.bodyMedium),
                        const SizedBox(height: 20),
                      ],

                      // Teaching Style
                      if (teachingStyle.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Teaching Style'),
                        const SizedBox(height: 8),
                        Text(
                          teachingStyle,
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Experience
                      if (experience.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Experience'),
                        const SizedBox(height: 8),
                        Text(
                          experience,
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Education
                      if (education.isNotEmpty) ...[
                        _buildSectionTitle(c, 'Education'),
                        const SizedBox(height: 8),
                        Text(
                          education,
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Reviews section
                      _buildSectionTitle(c, 'Reviews'),
                      const SizedBox(height: 8),
                      _buildReviewsSection(c, tutorId),

                      const SizedBox(height: 80), // Space for bottom button
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Floating Book Now button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(c).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton(
            onPressed: () {
              final tutorId = ModalRoute.of(c)!.settings.arguments as String;
              Navigator.pushNamed(c, Routes.bookingConfirm, arguments: tutorId);
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext c, String title) {
    return Text(
      title,
      style: Theme.of(
        c,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReviewsSection(BuildContext c, String tutorId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tutorProfiles')
          .doc(tutorId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is FirebaseException && error.code == 'permission-denied') {
            debugPrint('Tutor reviews permission denied for tutor $tutorId');
            return _buildNoReviewsCard();
          }
          return _buildReviewsErrorCard();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoReviewsCard();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final studentName = data['studentName'] as String? ?? 'Anonymous';
            final rating = (data['rating'] ?? 5) as num;
            final comment = data['comment'] as String? ?? '';
            final createdAt = data['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(comment),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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

  Widget _buildNoReviewsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_border,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No ratings yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews are temporarily unavailable',
            style: TextStyle(color: Colors.red.shade300, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
}
