import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_paths.dart';
import '../models/booking_model.dart';

class BookingRepo {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createBooking({
    required String studentId,
    required String tutorId,
    required String subject,
    required int minutes,
    required int price,
    String? message,
  }) async {
    final tutorSnap = await _db.collection('tutorProfiles').doc(tutorId).get();
    final t = tutorSnap.data() ?? {};
    final tutorName = (t['displayName'] ?? '') as String;
    final hourlyRate = (t['hourlyRate'] ?? 0) as num;

    final ref = _db.collection('bookings').doc();
    final createdAt = FieldValue.serverTimestamp();
    final acceptDeadline = Timestamp.fromDate(
      DateTime.now().add(const Duration(minutes: 15)),
    );

    await ref.set({
      'bookingId': ref.id,
      'studentId': studentId,
      'tutorId': tutorId,
      'studentName': _auth.currentUser?.displayName ?? '',
      'tutorName': tutorName,
      'subject': subject,
      'minutes': minutes,
      'price': price,
      'hourlyRate': hourlyRate,
      'message': message ?? '',
      'status': 'paid', // Simulated payment success
      'createdAt': createdAt,
      'paidAt': createdAt,
      'acceptDeadline': acceptDeadline,
    });
  }

  Future<void> ensureNotExpired(String bookingId, Map<String, dynamic> b) async {
    final deadline = (b['acceptDeadline'] as Timestamp?)?.toDate();
    final status = b['status'] as String?;
    final isPending = status == 'pending' || status == 'paid';
    if (deadline != null && DateTime.now().isAfter(deadline) && isPending) {
      await _db.doc('bookings/$bookingId').update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get bookings for a student (all their booked sessions)
  Stream<List<Booking>> getStudentBookings(String studentId, {String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db.collection(FP.bookings())
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true);
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    return query.snapshots().asyncMap((snapshot) async {
      await Future.wait(snapshot.docs.map((doc) => ensureNotExpired(doc.id, doc.data())));
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get bookings for a tutor (all sessions they're teaching)
  Stream<List<Booking>> getTutorBookings(String tutorId, {String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db.collection(FP.bookings())
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('createdAt', descending: true);
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    return query.snapshots().asyncMap((snapshot) async {
      await Future.wait(snapshot.docs.map((doc) => ensureNotExpired(doc.id, doc.data())));
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get all bookings for admin (entire platform activity)
  Stream<List<Booking>> getAllBookings({
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
  Query<Map<String, dynamic>> query = _db.collection(FP.bookings());
    
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      query = query.where('createdAt', isLessThan: endDate);
    }
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    query = query.orderBy('createdAt', descending: true).limit(limit);
    
    return query.snapshots().asyncMap((snapshot) async {
      await Future.wait(snapshot.docs.map((doc) => ensureNotExpired(doc.id, doc.data())));
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get booking statistics for admin dashboard
  Future<Map<String, int>> getBookingStats() async {
  final snapshot = await _db.collection(FP.bookings()).get();
  await Future.wait(snapshot.docs.map((doc) => ensureNotExpired(doc.id, doc.data())));
    final bookings = snapshot.docs;
    
    return {
      'total': bookings.length,
      'completed': bookings.where((d) => d.data()['status'] == 'completed').length,
      'pending': bookings.where((d) => d.data()['status'] == 'pending').length,
      'cancelled': bookings.where((d) => d.data()['status'] == 'cancelled').length,
    };
  }
}
