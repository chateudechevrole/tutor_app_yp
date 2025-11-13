import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Centralized service for Firebase Storage operations
///
/// Provides a clean interface for uploading files and managing
/// storage operations with automatic content-type detection.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads a file from XFile to the specified path
  ///
  /// Automatically detects content type from file extension.
  /// Returns the download URL of the uploaded file.
  Future<String> uploadFile(String path, XFile file) async {
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

    // Upload with metadata
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;
    final task = await ref.putFile(File(file.path), metadata);

    return await task.ref.getDownloadURL();
  }

  /// Gets the download URL for a file at the specified path
  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  /// Deletes a file at the specified path
  Future<void> delete(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}
