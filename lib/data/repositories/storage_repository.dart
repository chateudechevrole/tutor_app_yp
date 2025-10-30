import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  static const List<String> allowedChatMime = [
    'image/png',
    'image/jpeg',
    'application/pdf',
  ];

  static const int maxChatBytes = 10 * 1024 * 1024; // 10 MB

  Future<String> putFile(String path, File file) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  Future<String> putAvatar({required String uid, required File file}) async {
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  /// Uploads tutor avatar to profilePhotos/{uid}/avatar.jpg
  Future<String> uploadTutorAvatar(File file, String uid) async {
    final ref = _storage
        .ref()
        .child('profilePhotos')
        .child(uid)
        .child('avatar.jpg');

    final task = await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=3600',
      ),
    );
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadChatAttachment({
    required String threadId,
    required Uint8List data,
    required String fileName,
    required String mimeType,
  }) async {
    if (!allowedChatMime.contains(mimeType)) {
      throw FormatException('Unsupported file type');
    }

    if (data.length > maxChatBytes) {
      throw FormatException('File too large');
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'chatAttachments/$threadId/${timestamp}_$sanitizedName';

    final ref = _storage.ref().child(path);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: mimeType),
    );

    return await task.ref.getDownloadURL();
  }
}
