import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/models/student_profile_model.dart';
import '../../../data/repositories/student_profile_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../auth/login_screen.dart';
import '../booking_history_screen.dart';
import '../widgets/student_app_bar.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _repo = StudentProfileRepository();
  final _auth = FirebaseAuth.instance;
  final _storage = StorageRepository();
  final _db = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  StudentProfile? _profile;
  bool _loading = true;
  bool _notificationsEnabled = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile(StudentProfile profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _repo.upsertProfile(uid, profile);
      if (mounted) {
        setState(() => _profile = profile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _editDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != user.displayName) {
      try {
        // Update Firebase Auth profile
        await user.updateDisplayName(newName);

        // Update Firestore user doc
        await _db.collection('users').doc(user.uid).update({
          'displayName': newName,
        });

        if (mounted) {
          setState(() {}); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Photo Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _uploadingPhoto = true);

      // Upload to Firebase Storage
      final photoUrl = await _storage.putAvatar(
        uid: user.uid,
        file: File(image.path),
      );

      // Update Firebase Auth profile
      await user.updatePhotoURL(photoUrl);

      // Update Firestore user doc
      await _db.collection('users').doc(user.uid).update({
        'photoURL': photoUrl,
      });

      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditPreferences() {
    if (_profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _EditPreferencesSheet(profile: _profile!, onSave: _saveProfile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const StudentAppBar(title: 'My Profile', activeIndex: 2),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar & Name Section
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),

                  // Email (read-only)
                  _buildEmailCard(user),
                  const SizedBox(height: 16),

                  // Learning Preferences Card
                  _buildPreferencesCard(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Settings
                  _buildSettings(),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : user?.photoURL == null
                      ? Text(
                          (user?.displayName?.isNotEmpty == true
                                  ? user!.displayName![0]
                                  : 'S')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: InkWell(
                      onTap: _uploadingPhoto ? null : _changeProfilePhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.displayName ?? 'Student',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _editDisplayName,
                        tooltip: 'Edit name',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade: ${_profile?.grade ?? "Not set"}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(User? user) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.email),
        title: const Text('Email'),
        subtitle: Text(user?.email ?? 'Not available'),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    if (_profile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _showEditPreferences,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit preferences',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Grade'),
            trailing: Text(
              _profile!.grade,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.subject),
            title: const Text('Subjects'),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _profile!.subjects.map((subject) {
                return Chip(
                  label: Text(subject),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Languages'),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _profile!.languages.map((lang) {
                return Chip(
                  label: Text(lang),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Availability'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_profile!.availability.afterSchool)
                  const Text('• After school'),
                if (_profile!.availability.evening) const Text('• Evening'),
                if (_profile!.availability.weekend) const Text('• Weekend'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Booking History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentBookingHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Account Role'),
            trailing: Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Receive booking updates'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet for Editing Preferences
class _EditPreferencesSheet extends StatefulWidget {
  final StudentProfile profile;
  final Future<void> Function(StudentProfile) onSave;

  const _EditPreferencesSheet({required this.profile, required this.onSave});

  @override
  State<_EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends State<_EditPreferencesSheet> {
  late String _selectedGrade;
  late Set<String> _selectedSubjects;
  late Set<String> _selectedLanguages;
  late bool _afterSchool;
  late bool _evening;
  late bool _weekend;
  bool _saving = false;

  static const List<String> _grades = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Year 5',
    'Year 6',
    'Form 1',
    'Form 2',
    'Form 3',
    'Form 4',
    'Form 5',
    'Form 6',
  ];

  static const List<String> _availableSubjects = [
    'Math',
    'English',
    'Science',
    'BM',
    'Chinese',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
  ];

  static const List<String> _availableLanguages = ['EN', 'BM', '中文'];

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.profile.grade;
    _selectedSubjects = Set.from(widget.profile.subjects);
    _selectedLanguages = Set.from(widget.profile.languages);
    _afterSchool = widget.profile.availability.afterSchool;
    _evening = widget.profile.availability.evening;
    _weekend = widget.profile.availability.weekend;
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);

    final updatedProfile = StudentProfile(
      grade: _selectedGrade,
      subjects: _selectedSubjects.toList(),
      languages: _selectedLanguages.toList(),
      availability: StudentAvailability(
        afterSchool: _afterSchool,
        evening: _evening,
        weekend: _weekend,
      ),
      createdAt: widget.profile.createdAt,
      updatedAt: DateTime.now(),
    );

    await widget.onSave(updatedProfile);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Preferences',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Grade Dropdown
                  _buildSectionTitle('Grade'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGrade,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: _grades.map((grade) {
                      return DropdownMenuItem(value: grade, child: Text(grade));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGrade = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Subjects
                  _buildSectionTitle('Subjects'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSubjects.map((subject) {
                      final isSelected = _selectedSubjects.contains(subject);
                      return FilterChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSubjects.add(subject);
                            } else {
                              _selectedSubjects.remove(subject);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Languages
                  _buildSectionTitle('Languages'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableLanguages.map((lang) {
                      final isSelected = _selectedLanguages.contains(lang);
                      return FilterChip(
                        label: Text(lang),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLanguages.add(lang);
                            } else {
                              _selectedLanguages.remove(lang);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Availability
                  _buildSectionTitle('Availability'),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('After School'),
                          subtitle: const Text('3pm - 6pm'),
                          value: _afterSchool,
                          onChanged: (value) {
                            setState(() => _afterSchool = value);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Evening'),
                          subtitle: const Text('6pm - 9pm'),
                          value: _evening,
                          onChanged: (value) {
                            setState(() => _evening = value);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Weekend'),
                          subtitle: const Text('Saturday & Sunday'),
                          value: _weekend,
                          onChanged: (value) {
                            setState(() => _weekend = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
