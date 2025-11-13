import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import '../../core/storage_paths.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance {
    print('🏗️ StorageRepository initialized');
  }

  static const List<String> allowedChatMime = [
    'image/png',
    'image/jpeg',
    'application/pdf',
  ];

  static const int maxChatBytes = 10 * 1024 * 1024; // 10 MB

  Future<String> putFile(String path, File file) async {
    try {
      print('📤 Starting upload to path: $path');
      final ref = _storage.ref().child(path);

      // Determine content type from file extension
      final ext = path.split('.').last.toLowerCase();
      String? contentType;
      if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'pdf') {
        contentType = 'application/pdf';
      }

      print('📋 Content type: $contentType');
      print('📁 File size: ${file.lengthSync()} bytes');

      // Upload with metadata
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;
      final task = await ref.putFile(file, metadata);

      print('✅ Upload complete, getting download URL...');
      final url = await task.ref.getDownloadURL();
      print('✅ Download URL: $url');
      return url;
    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  Future<String> putAvatar({required String uid, required File file}) async {
    final ref = _storage.ref(tutorAvatarPath(uid));
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  /// Uploads tutor avatar to profilePhotos/{uid}/avatar.jpg
  Future<String> uploadTutorAvatar(File file, String uid) async {
    final ref = _storage.ref(profilePhotoPath(uid));

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
      throw const FormatException('Unsupported file type');
    }

    if (data.length > maxChatBytes) {
      throw const FormatException('File too large');
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${timestamp}_$sanitizedName';
    final path = chatAttachmentPath(threadId, uniqueFileName);

    final ref = _storage.ref().child(path);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: mimeType),
    );

    return await task.ref.getDownloadURL();
  }
}
