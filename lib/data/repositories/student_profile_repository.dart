import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_profile_model.dart';

/// Repository for managing student profiles in Firestore
class StudentProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's profile, or return defaults if not found
  Future<StudentProfile> getProfile([String? uid]) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) {
      return StudentProfile.defaults();
    }

    try {
      final doc = await _db.collection('studentProfiles').doc(userId).get();
      
      if (!doc.exists || doc.data() == null) {
        return StudentProfile.defaults();
      }

      return StudentProfile.fromJson(doc.data()!);
    } catch (e) {
      // Graceful fallback on any error
      return StudentProfile.defaults();
    }
  }

  /// Create or update the student profile
  Future<void> upsertProfile(String uid, StudentProfile profile) async {
    try {
      await _db.collection('studentProfiles').doc(uid).set(
            profile.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  /// Stream the current user's profile for real-time updates
  Stream<StudentProfile> watchProfile([String? uid]) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(StudentProfile.defaults());
    }

    return _db
        .collection('studentProfiles')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return StudentProfile.defaults();
      }
      return StudentProfile.fromJson(snapshot.data()!);
    }).handleError((_) => StudentProfile.defaults());
  }
}
