import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_routes.dart';
import '../../data/repositories/tutor_repository.dart';
import '../../theme/student_theme.dart';
import 'widgets/student_app_bar.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _repo = TutorRepo();

  String? _selectedGrade;
  String? _selectedSubject;
  String? _selectedLanguage;
  String? _selectedPurpose;

  final _grades = [
    'Primary 1',
    'Primary 2',
    'Primary 3',
    'Primary 4',
    'Primary 5',
    'Primary 6',
    'Form 1',
    'Form 2',
    'Form 3',
    'Form 4',
    'Form 5',
  ];

  final _subjects = [
    'BM',
    'English',
    'Science',
    'Maths',
    'Sejarah',
    'Geografi',
    'Moral',
    'Ekonomi',
    'Sastera',
    'Biologi',
    'Kimia',
    'Fizik',
  ];

  final _purposes = [
    'Homework',
    'Topic Help',
    'Exam Prep',
    'Oral Practice',
    'Essay Writing',
  ];

  final _languages = ['BM', 'Chinese', 'English'];

  void _clearFilters() {
    setState(() {
      _selectedGrade = null;
      _selectedSubject = null;
      _selectedLanguage = null;
      _selectedPurpose = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kStudentBg,
      extendBodyBehindAppBar: false,
      appBar: const StudentAppBar(title: 'Find Tutor Now ✨', activeIndex: 0),
      body: Column(
        children: [
          _buildFilterRow(),
          const SizedBox(height: 12),
          Expanded(child: _buildTutorList()),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: _selectedGrade ?? 'Grade',
              items: _grades,
              value: _selectedGrade,
              onSelected: (v) => setState(() => _selectedGrade = v),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: _selectedSubject ?? 'Subject',
              items: _subjects,
              value: _selectedSubject,
              onSelected: (v) => setState(() => _selectedSubject = v),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: _selectedPurpose ?? 'Purpose',
              items: _purposes,
              value: _selectedPurpose,
              onSelected: (v) => setState(() => _selectedPurpose = v),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: _selectedLanguage ?? 'Language',
              items: _languages,
              value: _selectedLanguage,
              onSelected: (v) => setState(() => _selectedLanguage = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onSelected,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (c) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select $label',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kStudentDeep,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) {
                    return FilterChip(
                      label: Text(item),
                      selected: value == item,
                      onSelected: (selected) {
                        onSelected(selected ? item : null);
                        Navigator.pop(c);
                      },
                    );
                  }).toList(),
                ),
                if (value != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      onSelected(null);
                      Navigator.pop(c);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kStudentDeep),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: kStudentDeep,
                fontSize: 14,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: kStudentDeep, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repo.searchOnlineVerified(
        grade: _selectedGrade,
        subject: _selectedSubject,
        language: _selectedLanguage,
        purpose: _selectedPurpose,
      ),
      builder: (context, snapshot) {
        try {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No tutors online for this filter yet.',
                    style: TextStyle(
                      color: kStudentDeep.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Debug: Log tutor count
          debugPrint(
            '[search] tutors returned: ${docs.length} (online + verified + not busy)',
          );

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No tutors online for this filter yet.',
                    style: TextStyle(
                      color: kStudentDeep.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final tutorId = docs[index].id;
              final name = data['displayName'] ?? 'Tutor';
              final photoUrl = data['photoUrl'] as String?;
              final subjects =
                  (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
              final grades =
                  (data['grades'] as List<dynamic>?)?.cast<String>() ?? [];
              final avgRating = data['avgRating'] as num?;

              final tags = <String>[];
              if (subjects.isNotEmpty) tags.add(subjects.first);
              if (grades.isNotEmpty) tags.add(grades.first);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kStudentDeep, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: kStudentDeep,
                    foregroundColor: Colors.white,
                    backgroundImage:
                        photoUrl != null &&
                            photoUrl.isNotEmpty &&
                            !photoUrl.startsWith('file://')
                        ? NetworkImage(photoUrl)
                        : null,
                    child:
                        photoUrl == null ||
                            photoUrl.isEmpty ||
                            photoUrl.startsWith('file://')
                        ? Text(name.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: kStudentDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: tags.isNotEmpty
                      ? Text(
                          tags.join(' • '),
                          style: TextStyle(
                            color: kStudentDeep.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: avgRating != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kStudentDeep.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: kStudentDeep,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: kStudentDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.tutorDetail,
                      arguments: tutorId,
                    );
                  },
                ),
              );
            },
          );
        } catch (_) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No tutors online for this filter yet.',
                  style: TextStyle(color: kStudentDeep.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
