import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/storage_repository.dart';
import '../../core/storage_paths.dart';
import '../../theme/tutor_theme.dart';
import 'tutor_waiting_screen.dart';
import 'shell/tutor_shell.dart';

class TutorVerifyScreen extends StatefulWidget {
  const TutorVerifyScreen({super.key});
  @override
  State<TutorVerifyScreen> createState() => _TutorVerifyScreenState();
}

class _TutorVerifyScreenState extends State<TutorVerifyScreen> {
  File? icFile;
  File? eduFile;
  File? bankFile;
  String? icUrl;
  String? eduUrl;
  String? bankUrl;
  bool uploading = false;
  final _storage = StorageRepository();

  Future<void> pickAndUploadFile(
    String logicalName,
    Function(File, String) onSuccess,
  ) async {
    print('📷 Picking file for: $logicalName');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      print('❌ No file picked');
      return;
    }

    final file = File(pickedFile.path);
    if (!mounted) return;

    setState(() => uploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    print('👤 User ID: $uid');

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = file.path.split('.').last;
      final fileName = '${timestamp}_$logicalName.$ext';
      final uploadPath = verificationPath(uid, fileName);
      print('📤 Upload path: $uploadPath');

      final url = await _storage.putFile(uploadPath, file);
      print('✅ Upload successful, URL received');
      onSuccess(file, url);
    } catch (e) {
      print('❌ Upload failed in widget: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To begin tutoring, please upload the following:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildFileRow(
                'IC / MyKad',
                icFile,
                icUrl,
                () => pickAndUploadFile('ic', (f, url) {
                  if (mounted) {
                    setState(() {
                      icFile = f;
                      icUrl = url;
                    });
                  }
                }),
              ),
              const SizedBox(height: 16),
              _buildFileRow(
                'Highest Education Certificate',
                eduFile,
                eduUrl,
                () => pickAndUploadFile('edu_cert', (f, url) {
                  if (mounted) {
                    setState(() {
                      eduFile = f;
                      eduUrl = url;
                    });
                  }
                }),
              ),
              const SizedBox(height: 16),
              _buildFileRow(
                'Bank Account Statement (last page)',
                bankFile,
                bankUrl,
                () => pickAndUploadFile('bank_stmt', (f, url) {
                  if (mounted) {
                    setState(() {
                      bankFile = f;
                      bankUrl = url;
                    });
                  }
                }),
              ),
              const SizedBox(height: 24),
              uploading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                (icUrl != null &&
                                    eduUrl != null &&
                                    bankUrl != null)
                                ? () async {
                                    setState(() => uploading = true);
                                    try {
                                      final uid = FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .uid;
                                      await FirebaseFirestore.instance
                                          .doc('verificationRequests/$uid')
                                          .set({
                                            'status': 'pending',
                                            'submittedAt':
                                                FieldValue.serverTimestamp(),
                                            'files': {
                                              'icUrl': icUrl!,
                                              'eduCertUrl': eduUrl!,
                                              'bankStmtUrl': bankUrl!,
                                            },
                                          }, SetOptions(merge: true));
                                      await FirebaseFirestore.instance
                                          .doc('users/$uid')
                                          .set({
                                            'tutorVerified': false,
                                          }, SetOptions(merge: true));
                                      if (!mounted) return;
                                      Navigator.of(c).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TutorWaitingScreen(),
                                        ),
                                        (r) => false,
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(c).showSnackBar(
                                          SnackBar(
                                            content: Text('Submit failed: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => uploading = false);
                                      }
                                    }
                                  }
                                : null,
                            child: const Text('Submit All and Verify'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () {
                              Navigator.of(c).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const TutorShell(),
                                ),
                                (r) => false,
                              );
                            },
                            child: const Text('Complete Later'),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileRow(
    String label,
    File? file,
    String? url,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (file != null)
                Text(
                  file.path.split('/').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: kPrimary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        if (url == null)
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.upload_file),
            color: kPrimary,
          )
        else
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.refresh),
                color: kPrimary,
              ),
            ],
          ),
      ],
    );
  }
}
