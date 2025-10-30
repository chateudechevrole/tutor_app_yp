import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/repositories/tutor_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../theme/tutor_theme.dart';
import '../../core/constants/subjects_catalog.dart';
import '../../core/constants/languages_catalog.dart';
import '../../core/constants/grades_catalog.dart';

class TutorProfileEditScreen extends StatefulWidget {
  const TutorProfileEditScreen({super.key});
  @override
  State<TutorProfileEditScreen> createState() => _TutorProfileEditScreenState();
}

class _TutorProfileEditScreenState extends State<TutorProfileEditScreen> {
  final _displayName = TextEditingController();
  final _intro = TextEditingController();
  final _teachingStyle = TextEditingController();
  final _experience = TextEditingController();
  final _education = TextEditingController();
  final _certificates = TextEditingController();
  List<String> _languages = [];
  List<String> _subjects = [];
  List<String> _grades = [];
  String? _photoUrl;
  bool _loading = false;
  final _repo = TutorRepo();
  final _storage = StorageRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .doc('tutorProfiles/$uid')
        .get();
    if (snap.exists && mounted) {
      final data = snap.data()!;
      setState(() {
        _displayName.text = data['displayName'] ?? '';
        _intro.text = data['intro'] ?? '';
        _teachingStyle.text = data['teachingStyle'] ?? '';
        _experience.text = data['experience'] ?? '';
        _education.text = data['education'] ?? '';
        _certificates.text = data['certificates']?.join(', ') ?? '';
        _languages = List<String>.from(data['languages'] ?? []);
        _subjects = List<String>.from(data['subjects'] ?? []);
        _grades = List<String>.from(data['grades'] ?? []);
        _photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _repo.updateProfile(uid, {
        'displayName': _displayName.text,
        'intro': _intro.text,
        'teachingStyle': _teachingStyle.text,
        'experience': _experience.text,
        'education': _education.text,
        'certificates': _certificates.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'languages': _languages,
        'subjects': _subjects,
        'grades': _grades,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Theme(
      data: tutorTheme,
      child: SafeArea(
        child: Column(
          children: [
            // Save button header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: tutorTheme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loading ? null : _saveProfile,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: kPrimary.withValues(alpha: 0.1),
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null
                    ? const Icon(Icons.person, size: 50, color: kPrimary)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: kPrimary,
                  radius: 18,
                  child: IconButton(
                    onPressed: _pickAndUploadPhoto,
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'This profile is visible to students',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _displayName,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _intro,
          decoration: const InputDecoration(
            labelText: 'Introduction',
            hintText: 'Brief intro about yourself',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildLanguagePicker(),
        const SizedBox(height: 16),
        TextField(
          controller: _teachingStyle,
          decoration: const InputDecoration(
            labelText: 'Teaching Style',
            hintText: 'e.g., Interactive, patient, exam-focused',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildSubjectPicker(),
        const SizedBox(height: 16),
        _buildGradePicker(),
        const SizedBox(height: 16),
        TextField(
          controller: _experience,
          decoration: const InputDecoration(
            labelText: 'Experience',
            hintText: 'Years of teaching, notable achievements',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _education,
          decoration: const InputDecoration(
            labelText: 'Education',
            hintText: 'Degrees, institutions',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _certificates,
          decoration: const InputDecoration(
            labelText: 'Certificates (comma-separated URLs)',
            hintText: 'Optional',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _saveProfile,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Profile'),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _loading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Use the new repository methods
      final file = File(pickedFile.path);
      final downloadUrl = await _storage.uploadTutorAvatar(file, uid);
      await _repo.saveAvatarUrl(uid, downloadUrl);

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    }
  }

  Widget _buildSubjectPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Subjects',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_subjects.length}/5 selected)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._subjects.map(
              (subject) => Chip(
                label: Text(subject),
                onDeleted: () {
                  setState(() => _subjects.remove(subject));
                },
              ),
            ),
            ActionChip(
              label: const Text('+ Add'),
              onPressed: _subjects.length >= 5 ? null : _pickSubjects,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickSubjects() async {
    final tempSelected = Set<String>.from(_subjects);

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Select Subjects',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${tempSelected.length}/5',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSubjectsCatalog.map((subject) {
                  final isSelected = tempSelected.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected && tempSelected.length < 5) {
                          tempSelected.add(subject);
                        } else if (!selected) {
                          tempSelected.remove(subject);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _subjects = tempSelected.toList());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Languages Spoken',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_languages.length} selected)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._languages.map(
              (lang) => Chip(
                label: Text(lang),
                onDeleted: () {
                  setState(() => _languages.remove(lang));
                },
              ),
            ),
            ActionChip(label: const Text('+ Add'), onPressed: _pickLanguages),
          ],
        ),
      ],
    );
  }

  Future<void> _pickLanguages() async {
    final tempSelected = Set<String>.from(_languages);

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Languages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kLanguagesCatalog.map((lang) {
                  final isSelected = tempSelected.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempSelected.add(lang);
                        } else {
                          tempSelected.remove(lang);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _languages = tempSelected.toList());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Grade Levels',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_grades.length} selected)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._grades.map(
              (grade) => Chip(
                label: Text(grade),
                onDeleted: () {
                  setState(() => _grades.remove(grade));
                },
              ),
            ),
            ActionChip(label: const Text('+ Add'), onPressed: _pickGrades),
          ],
        ),
      ],
    );
  }

  Future<void> _pickGrades() async {
    final tempSelected = Set<String>.from(_grades);

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Grade Levels',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kGradesCatalog.map((grade) {
                  final isSelected = tempSelected.contains(grade);
                  return FilterChip(
                    label: Text(grade),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempSelected.add(grade);
                        } else {
                          tempSelected.remove(grade);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _grades = tempSelected.toList());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
