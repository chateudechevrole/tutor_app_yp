import 'package:cloud_firestore/cloud_firestore.dart';

class TutorAvailabilityRepository {
  final FirebaseFirestore _db;

  TutorAvailabilityRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Check if a tutor is available for booking
  /// Returns true only if:
  /// 1. acceptingBookings is true (or null, defaulting to true)
  /// 2. No pending sessions exist for this tutor
  Future<bool> isTutorBookable(String tutorId) async {
    try {
      // Check acceptingBookings flag
      final userDoc = await _db.doc('users/$tutorId').get();
      final userData = userDoc.data();
      final acceptingBookings = userData?['acceptingBookings'] ?? true;

      if (!acceptingBookings) {
        return false;
      }

      // Check for pending sessions
      final pendingSessions = await _db
          .collection('classSessions')
          .where('tutorId', isEqualTo: tutorId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return pendingSessions.docs.isEmpty;
    } catch (e) {
      // On error, default to not bookable (safer)
      return false;
    }
  }

  /// Batch check multiple tutors for availability
  /// Returns map of tutorId -> isBookable
  Future<Map<String, bool>> checkMultipleTutors(List<String> tutorIds) async {
    final results = <String, bool>{};

    await Future.wait(
      tutorIds.map((id) async {
        results[id] = await isTutorBookable(id);
      }),
    );

    return results;
  }

  /// Stream to watch tutor availability changes
  Stream<bool> watchTutorAvailability(String tutorId) {
    return _db.doc('users/$tutorId').snapshots().asyncMap((userDoc) async {
      final userData = userDoc.data();
      final acceptingBookings = userData?['acceptingBookings'] ?? true;

      if (!acceptingBookings) {
        return false;
      }

      final pendingSessions = await _db
          .collection('classSessions')
          .where('tutorId', isEqualTo: tutorId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return pendingSessions.docs.isEmpty;
    });
  }
}
