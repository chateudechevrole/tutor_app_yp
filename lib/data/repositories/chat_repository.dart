import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_paths.dart';

class ChatRepo {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String threadId) =>
      _db.collection(FP.chatMessages(threadId)).orderBy('ts').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> threadsForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> ensureThread(String threadId, List<String> members) async {
    await _db.collection('chats').doc(threadId).set({
      'members': members,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    }, SetOptions(merge: true));
  }

  Future<void> send(String threadId, String uid, String text) async {
    if (text.trim().isEmpty) return;

    final parts = threadId.split('_');
    List<String> members;
    if (parts.length >= 2) {
      members = [parts[0], parts[1]];
    } else {
      members = [uid];
    }

    await _db.collection('chats').doc(threadId).set({
      'members': members,
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection(FP.chatMessages(threadId)).add({
      'senderId': uid,
      'text': text.trim(),
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> sendAttachment(
    String threadId,
    String uid, {
    required String url,
    required String fileName,
    required String mimeType,
  }) async {
    final parts = threadId.split('_');
    List<String> members;
    if (parts.length >= 2) {
      members = [parts[0], parts[1]];
    } else {
      members = [uid];
    }

    final preview = 'Attachment: $fileName';

    await _db.collection('chats').doc(threadId).set({
      'members': members,
      'lastMessage': preview,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection(FP.chatMessages(threadId)).add({
      'senderId': uid,
      'text': preview,
      'attachmentUrl': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
