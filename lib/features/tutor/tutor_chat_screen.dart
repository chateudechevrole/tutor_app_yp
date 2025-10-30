import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../theme/tutor_theme.dart';

class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({super.key});
  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  static const List<String> _allowedMime = StorageRepository.allowedChatMime;
  static const int _maxBytes = StorageRepository.maxChatBytes;

  final msg = TextEditingController();
  final _repo = ChatRepo();
  final _storage = StorageRepository();

  bool _sendingAttachment = false;

  @override
  Widget build(BuildContext c) {
    final threadId = ModalRoute.of(c)!.settings.arguments as String;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          actions: [
            FilledButton.tonal(
              onPressed: () {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('Start Class - Coming Soon')),
                );
              },
              child: const Text('Start Class'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repo.messages(threadId),
                builder: (ctx, s) {
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = s.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data();
                      final mine = d['senderId'] == uid;
                      final text = (d['text'] ?? '') as String;
                      final attachmentUrl = d['attachmentUrl'] as String?;
                      final fileName = d['fileName'] as String?;
                      Widget content;

                      if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
                        content = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (text.isNotEmpty) Text(text),
                            TextButton.icon(
                              onPressed: () => _openAttachment(attachmentUrl),
                              icon: const Icon(Icons.attach_file),
                              label: Text(fileName ?? 'Attachment'),
                            ),
                          ],
                        );
                      } else {
                        content = Text(text);
                      }
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mine
                                ? kPrimary.withValues(alpha: 0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: content,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sendingAttachment
                        ? null
                        : () => _pickAttachment(threadId, uid),
                    icon: _sendingAttachment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: msg,
                      decoration: const InputDecoration(hintText: 'Type...'),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (msg.text.trim().isNotEmpty) {
                        _repo.send(threadId, uid, msg.text.trim());
                        msg.clear();
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment')),
      );
    }
  }

  Future<void> _pickAttachment(String threadId, String uid) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final mimeType = _resolveMime(file);

    if (file.bytes == null) {
      _showSnack('Unable to read file');
      return;
    }

    final Uint8List data = file.bytes!;

    if (!_allowedMime.contains(mimeType)) {
      _showSnack('File type not supported');
      return;
    }

    if (data.length > _maxBytes || file.size > _maxBytes) {
      _showSnack('File exceeds 10 MB limit');
      return;
    }

    if (!mounted) return;
    setState(() => _sendingAttachment = true);

    try {
      final url = await _storage.uploadChatAttachment(
        threadId: threadId,
        data: data,
        fileName: file.name,
        mimeType: mimeType,
      );

      await _repo.sendAttachment(
        threadId,
        uid,
        url: url,
        fileName: file.name,
        mimeType: mimeType,
      );

      _showSnack('Attachment sent');
    } catch (e) {
      _showSnack('Failed to send attachment: $e');
    } finally {
      if (mounted) {
        setState(() => _sendingAttachment = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _resolveMime(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }
}
