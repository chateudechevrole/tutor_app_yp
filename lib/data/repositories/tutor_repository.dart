import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/storage_paths.dart';
import '../../services/firestore_paths.dart';
import 'storage_repository.dart';

class TutorRepo {
  final FirebaseFirestore _db;
  final _storage = StorageRepository();

  TutorRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> setOnline(String uid, bool online) async {
    final batch = _db.batch();
    final tutorDoc = _db.doc(FP.tutorProfiles(uid));
    final userDoc = _db.doc(FP.users(uid));

    batch.set(tutorDoc, {
      // Canonical field
      'online': online,
      // Backward-compat: also update legacy field used by older code paths
      'isOnline': online, // TODO: remove after all reads migrate to `online`
      'status': online ? 'online' : 'offline',
      'lastStatusChange': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userDoc, {
      'acceptingBookings': online,
      'online': online,
      'isOnline': online,
      'lastStatusChange': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> search({
    String subject = '',
    String grade = '',
    String language = '',
  }) {
    return _db
        .collection('tutorProfiles')
        .where('online', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> searchOnlineVerified({
    String? grade,
    String? subject,
    String? language,
    String? purpose,
  }) {
    // TODO: Composite index required for: online + verified + isBusy + array filters
    // See firestore.indexes.json for index configuration
    var q = _db
        .collection('tutorProfiles')
        .where('online', isEqualTo: true)
        .where('verified', isEqualTo: true);

    // Availability filter note:
    // We previously filtered by `isBusy == false`, but not all profiles maintain this flag.
    // To avoid hiding online tutors, we temporarily skip this filter.
    // TODO: Re-enable when `tutorProfiles.available` (or reliable availability flag) is maintained.

    // Only apply ONE array filter at a time (Firestore limitation)
    if (grade != null && grade.isNotEmpty) {
      q = q.where('grades', arrayContains: grade);
    } else if (subject != null && subject.isNotEmpty) {
      q = q.where('subjects', arrayContains: subject);
    } else if (language != null && language.isNotEmpty) {
      q = q.where('languages', arrayContains: language);
    } else if (purpose != null && purpose.isNotEmpty) {
      q = q.where('purposeTags', arrayContains: purpose);
    }

    return q.snapshots();
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final url = await _storage.putFile(tutorAvatarPath(uid), file);
    await _db.doc(FP.users(uid)).set({
      'photoUrl': url,
    }, SetOptions(merge: true));
    await _db.doc(FP.tutorProfiles(uid)).set({
      'photoUrl': url,
    }, SetOptions(merge: true));
    return url;
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.doc(FP.tutorProfiles(uid)).set(data, SetOptions(merge: true));
    if (data.containsKey('displayName')) {
      await _db.doc(FP.users(uid)).set({
        'displayName': data['displayName'],
      }, SetOptions(merge: true));
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamVerificationStatus(
    String uid,
  ) {
    return _db.doc('verificationRequests/$uid').snapshots();
  }

  Future<void> submitVerification(
    String uid,
    Map<String, String> fileUrls,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    await _db.doc('verificationRequests/$uid').set({
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'files': fileUrls,
      'tutorEmail': currentUser?.email,
      'tutorName': currentUser?.displayName ?? 'User',
    }, SetOptions(merge: true));
  }

  /// Saves avatar URL to tutorProfiles/{uid}
  Future<void> saveAvatarUrl(String uid, String url) {
    return _db.collection('tutorProfiles').doc(uid).set({
      'photoUrl': url,
    }, SetOptions(merge: true));
  }

  Future<void> submitReview({
    required String tutorId,
    required String studentId,
    required String studentName,
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    final reviewRef = _db
        .collection('tutorProfiles')
        .doc(tutorId)
        .collection('reviews')
        .doc();

    await _db.runTransaction((tx) async {
      final tutorRef = _db.collection('tutorProfiles').doc(tutorId);
      tx.set(reviewRef, {
        'reviewId': reviewRef.id,
        'studentId': studentId,
        'studentName': studentName,
        'tutorId': tutorId,
        'rating': rating,
        'comment': comment,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final snapshot = await tx.get(tutorRef);
      final data = snapshot.data() ?? {};
      final currentSum = (data['sumRatings'] ?? 0).toDouble();
      final currentCount = (data['totalReviews'] ?? 0) as num;

      final newSum = currentSum + rating;
      final newCount = currentCount.toInt() + 1;

      tx.update(tutorRef, {
        'sumRatings': newSum,
        'totalReviews': newCount,
        'rating': newSum / newCount,
      });
    });
  }
}
