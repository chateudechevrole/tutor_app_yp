import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Deploy: firebase deploy --only firestore:indexes

class AdminRepo {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUser(String uid) async =>
      (await _db.doc('users/$uid').get()).data();

  Future<Map<String, dynamic>> resolveTutorMeta(
    String uid,
    Map<String, dynamic> reqData,
  ) async {
    final user = await _db.doc('users/$uid').get();
    final m = <String, dynamic>{};
    m['name'] = (user.data()?['displayName'] ?? reqData['tutorName'] ?? uid);
    m['email'] = (user.data()?['email'] ?? reqData['tutorEmail']);
    return m;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingVerifications() {
    return _db
        .collection('verificationRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> approveTutor(String tutorId, {String? note}) async {
    final b = _db.batch();
    final now = FieldValue.serverTimestamp();
    final adminUid = FirebaseAuth.instance.currentUser!.uid;

    final reqRef = _db.doc('verificationRequests/$tutorId');
    final profRef = _db.doc('tutorProfiles/$tutorId');
    final userRef = _db.doc('users/$tutorId');
    final notifRef = _db.collection('notifications/$tutorId/items').doc();

    b.update(reqRef, {
      'status': 'approved',
      'reviewerId': adminUid,
      'reviewedAt': now,
      if (note != null && note.trim().isNotEmpty) 'reviewNote': note.trim(),
    });

    b.set(profRef, {
      'verified': true,
      'verifiedAt': now,
      'verifiedBy': adminUid,
      'status': 'verified',
    }, SetOptions(merge: true));

    b.set(userRef, {
      'tutorVerified': true,
      'updatedAt': now,
    }, SetOptions(merge: true));

    b.set(notifRef, {
      'type': 'verification_approved',
      'ts': now,
      'title': 'Verification approved',
      'body': 'You can now accept bookings.',
      'reviewerId': adminUid,
    });

    await b.commit();
  }

  Future<void> rejectTutor(String tutorId, {required String reason}) async {
    final b = _db.batch();
    final now = FieldValue.serverTimestamp();
    final adminUid = FirebaseAuth.instance.currentUser!.uid;

    final reqRef = _db.doc('verificationRequests/$tutorId');
    final profRef = _db.doc('tutorProfiles/$tutorId');
    final userRef = _db.doc('users/$tutorId');
    final notifRef = _db.collection('notifications/$tutorId/items').doc();

    b.update(reqRef, {
      'status': 'rejected',
      'reviewerId': adminUid,
      'reviewedAt': now,
      'reviewNote': reason.trim(),
    });

    b.set(profRef, {
      'verified': false,
      'status': 'rejected',
      'rejectedAt': now,
      'rejectedBy': adminUid,
    }, SetOptions(merge: true));

    b.set(userRef, {
      'tutorVerified': false,
      'updatedAt': now,
    }, SetOptions(merge: true));

    b.set(notifRef, {
      'type': 'verification_rejected',
      'ts': now,
      'title': 'Verification rejected',
      'body': reason.trim().isEmpty
          ? 'Please resubmit your documents.'
          : reason.trim(),
      'reviewerId': adminUid,
    });

    await b.commit();
  }
}
