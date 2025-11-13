# QuickTutor - Unit Testing Inventory

**Date:** November 13, 2025  
**Status:** Minimal Testing Coverage

---

## Current Unit Test Coverage

### ✅ Existing Tests (1 file)

**File:** `test/widget_test.dart`
- **Test:** Minimal MaterialApp renders
- **Type:** Widget smoke test
- **Coverage:** Basic app initialization

---

## Recommended Unit Tests by Module

### 1. User Registration & Authentication

**Missing Tests:**
- Email validation logic
- Password strength validation
- Role selection persistence
- Firebase Auth error handling
- Token refresh logic
- Logout state cleanup

**Suggested Test Files:**
- `test/auth/email_validator_test.dart`
- `test/auth/auth_repository_test.dart`
- `test/auth/role_guard_test.dart`

---

### 2. Tutor Verification & Onboarding

**Missing Tests:**
- File size validation (< 10MB)
- File type validation (JPEG, PNG, PDF)
- Upload path generation
- Verification status transitions
- Admin approval/rejection logic

**Suggested Test Files:**
- `test/verification/file_validator_test.dart`
- `test/verification/verification_repository_test.dart`
- `test/repositories/storage_repository_test.dart`

---

### 3. Tutor Online Status & Availability

**Missing Tests:**
- Status toggle logic (online/offline)
- Auto-busy when booking accepted
- Auto-available when class ends
- Presence sync (online/isOnline fields)
- isBusy flag management

**Suggested Test Files:**
- `test/repositories/tutor_repository_test.dart`
- `test/models/tutor_status_test.dart`

---

### 4. Tutor Discovery & Instant Booking

**Missing Tests:**
- Search query builder (filters)
- Array-contains filter logic
- Booking status transitions (pending → accepted → in_progress → completed)
- Request/accept/reject workflows
- Cancellation logic

**Suggested Test Files:**
- `test/repositories/booking_repository_test.dart`
- `test/services/search_service_test.dart`
- `test/models/booking_test.dart`

---

### 5. Payment Simulation & Earnings

**Missing Tests:**
- Payment record creation
- Earnings calculation
- Total earnings update
- Refund logic
- Duplicate payment prevention

**Suggested Test Files:**
- `test/repositories/payment_repository_test.dart`
- `test/services/earnings_calculator_test.dart`

---

### 6. In-App Chat & File Upload

**Missing Tests:**
- Message serialization/deserialization
- File MIME type validation
- File size validation (< 10MB)
- Chat read-only logic (24h after class)
- Unread count calculation

**Suggested Test Files:**
- `test/repositories/message_repository_test.dart`
- `test/repositories/chat_repository_test.dart`
- `test/models/chat_message_test.dart`
- `test/services/chat_readonly_checker_test.dart`

---

### 7. Virtual Classroom

**Missing Tests:**
- Duration calculation (startTime → endTime)
- Early start validation (< 15 min before)
- Late start detection (> 30 min after)
- Class status transitions
- Actual vs scheduled duration comparison

**Suggested Test Files:**
- `test/services/classroom_service_test.dart`
- `test/utils/duration_calculator_test.dart`

---

### 8. Feedback & Rating

**Missing Tests:**
- Rating validation (1-5 stars)
- Average rating calculation
- Duplicate rating prevention
- Review count update
- Rating eligibility check (completed booking only)

**Suggested Test Files:**
- `test/repositories/review_repository_test.dart`
- `test/services/rating_calculator_test.dart`

---

### 9. Admin Management

**Missing Tests:**
- User ban/warn logic
- Access restriction validation
- Report filtering
- Statistics aggregation
- Permission checks

**Suggested Test Files:**
- `test/repositories/admin_repository_test.dart`
- `test/services/moderation_service_test.dart`

---

### 10. Notifications

**Missing Tests:**
- FCM token registration
- Notification payload parsing
- In-app notification filtering
- Badge count calculation
- Mark as read logic

**Suggested Test Files:**
- `test/services/notification_service_test.dart`
- `test/services/push_service_test.dart`

---

### 11. Booking History

**Missing Tests:**
- Date range filtering
- Status filtering
- Search/query logic
- Receipt data formatting
- Total spent/earned calculation

**Suggested Test Files:**
- `test/services/history_service_test.dart`
- `test/utils/date_filter_test.dart`

---

## Test Coverage Summary

| Module | Existing Tests | Missing Tests | Priority |
|--------|----------------|---------------|----------|
| Authentication | 0 | 6 | HIGH |
| Verification | 0 | 5 | HIGH |
| Tutor Status | 0 | 5 | HIGH |
| Discovery/Booking | 0 | 5 | CRITICAL |
| Payment | 0 | 5 | MEDIUM |
| Chat/Upload | 0 | 5 | MEDIUM |
| Classroom | 0 | 5 | MEDIUM |
| Rating | 0 | 5 | MEDIUM |
| Admin | 0 | 5 | LOW |
| Notifications | 0 | 5 | MEDIUM |
| History | 0 | 5 | LOW |

**Total Coverage:** 1 / 57+ recommended tests

---

## Test Types Needed

### Unit Tests (Business Logic)
- Repository methods (CRUD operations)
- Service layer logic (calculations, validations)
- Model serialization/deserialization
- Utility functions (date, duration, formatting)
- Validators (email, file, status)

### Widget Tests
- Login/signup forms
- Search filters UI
- Chat message widgets
- Booking cards
- Rating widgets
- Profile screens

### Integration Tests
- End-to-end booking flow
- Chat with file upload
- Payment + earnings update
- Status transitions
- Notification delivery

---

## Recommended Testing Priority

### Phase 1: Critical Path (HIGH Priority)
1. **Booking Repository Tests** - Core business logic
2. **Tutor Status Tests** - Online/offline presence
3. **Auth Repository Tests** - User security
4. **Search Service Tests** - Tutor discovery

### Phase 2: User Experience (MEDIUM Priority)
5. **Chat/Message Tests** - Communication
6. **Payment Tests** - Transaction integrity
7. **Rating Calculator Tests** - Tutor scoring
8. **Notification Tests** - User engagement

### Phase 3: Admin & Polish (LOW Priority)
9. **Admin Repository Tests** - Management tools
10. **History Service Tests** - Record keeping
11. **Widget Tests** - UI components

---

## Sample Test Template

```dart
// test/repositories/booking_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:quicktutor_2/data/repositories/booking_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late BookingRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = BookingRepository(firestore: fakeFirestore);
  });

  group('BookingRepository', () {
    test('createBooking should save booking to Firestore', () async {
      // Arrange
      final bookingData = {
        'studentUid': 'student123',
        'tutorUid': 'tutor456',
        'status': 'pending',
      };

      // Act
      final bookingId = await repository.createBooking(bookingData);

      // Assert
      expect(bookingId, isNotEmpty);
      final doc = await fakeFirestore.collection('bookings').doc(bookingId).get();
      expect(doc.exists, true);
      expect(doc['status'], 'pending');
    });

    test('acceptBooking should update status to accepted', () async {
      // Arrange
      final bookingId = 'booking123';
      await fakeFirestore.collection('bookings').doc(bookingId).set({
        'status': 'pending',
      });

      // Act
      await repository.acceptBooking(bookingId);

      // Assert
      final doc = await fakeFirestore.collection('bookings').doc(bookingId).get();
      expect(doc['status'], 'accepted');
    });
  });
}
```

---

## Dependencies for Testing

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  fake_cloud_firestore: ^3.0.0
  firebase_auth_mocks: ^0.14.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

---

## Next Steps

1. ✅ Install testing dependencies
2. ✅ Create test directory structure
3. ✅ Write Phase 1 critical tests (Booking, Status, Auth, Search)
4. ✅ Set up CI/CD to run tests automatically
5. ✅ Aim for 80%+ code coverage
6. ✅ Add widget tests for key UI components
7. ✅ Create integration tests for critical paths

---

**Status:** ⚠️ Testing infrastructure needs significant development  
**Recommendation:** Prioritize Phase 1 tests before production launch
