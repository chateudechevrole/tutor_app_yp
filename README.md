# QuickTutor# quicktutor_2



An instant tutoring platform that connects students with verified tutors for real-time learning sessions. Built with Flutter and Firebase.A new Flutter project.



## 🎯 Features## Getting Started



### For StudentsThis project is a starting point for a Flutter application.

- **Instant Tutor Discovery** - Search tutors by subject, grade level, and language

- **Real-time Booking** - Request sessions and get instant acceptanceA few resources to get you started if this is your first Flutter project:

- **In-App Chat** - Communicate with tutors before and during sessions

- **Virtual Classroom** - One-tap join for seamless learning- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- **Rating & Reviews** - Rate tutors after each completed session- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

- **Booking History** - Track past sessions and payments

For help getting started with Flutter development, view the

### For Tutors[online documentation](https://docs.flutter.dev/), which offers tutorials,

- **Verification System** - Upload credentials for admin approvalsamples, guidance on mobile development, and a full API reference.

- **Online Status Control** - Toggle availability on/off
- **Auto-Busy Management** - Automatically marked as busy during active classes
- **Earnings Dashboard** - Track income and booking statistics
- **Profile Management** - Set subjects, rates, and availability

### For Admins
- **Tutor Verification** - Review and approve tutor credentials
- **User Management** - Warn, restrict, or ban users
- **Platform Monitoring** - View bookings, chats, and reports
- **Statistics Dashboard** - Platform-wide analytics

## 🚀 Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **State Management**: Provider / StatefulWidget
- **Architecture**: Repository Pattern
- **Testing**: flutter_test, fake_cloud_firestore
- **Platform**: iOS (iPhone 13.0+), Android (coming soon)

## 📱 Screenshots

*Coming soon*

## 🏗️ Project Structure

```
lib/
├── core/                       # Core utilities and configuration
│   ├── app_routes.dart         # Route definitions
│   ├── app_theme.dart          # Theme configuration
│   ├── bootstrap.dart          # App initialization
│   ├── firebase_singleton.dart # Firebase initialization
│   └── storage_paths.dart      # Firebase Storage paths
├── data/
│   ├── models/                 # Data models (AppUser, Booking, etc.)
│   └── repositories/           # Data access layer
├── features/
│   ├── admin/                  # Admin dashboard and management
│   ├── auth/                   # Authentication screens
│   ├── gates/                  # Role-based routing guards
│   ├── student/                # Student features and UI
│   └── tutor/                  # Tutor features and UI
├── services/                   # Business logic services
│   ├── push/                   # Push notification handlers
│   └── notification_service.dart
├── theme/                      # Theme files per role
├── main.dart                   # Generic entry point
├── main_admin.dart             # Admin-only entry
├── main_student.dart           # Student-only entry
└── main_tutor.dart             # Tutor-only entry
```

## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart 3.5.0 or higher
- Xcode 15.0+ (for iOS)
- CocoaPods 1.16.0+
- Firebase project with Firestore, Auth, Storage, and Messaging enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/quicktutor_2.git
   cd quicktutor_2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

3. **Configure Firebase** (Required)
   
   ⚠️ **You must create your own Firebase project** - The Firebase configuration files are excluded from this repository for security.
   
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore, Authentication, Storage, and Cloud Messaging
   - Download configuration files:
     - iOS: `GoogleService-Info.plist`
     - Android: `google-services.json`
   - Run FlutterFire CLI:
     ```bash
     flutterfire configure
     ```
   - This will generate `lib/firebase_options.dart`
   - Place platform files:
     - iOS: `ios/Runner/GoogleService-Info.plist`
     - Android: `android/app/google-services.json`

4. **Set up Firestore indexes**
   
   Deploy the required composite indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

5. **Run the app**
   ```bash
   # Student app
   flutter run -t lib/main_student.dart

   # Tutor app
   flutter run -t lib/main_tutor.dart

   # Admin app
   flutter run -t lib/main_admin.dart
   ```

## 🗄️ Firestore Database Structure

```
users/
  {uid}/
    - role: string (student/tutor/admin)
    - email: string
    - displayName: string
    - tutorVerified: boolean
    - fcmToken: string

tutorProfiles/
  {uid}/
    - online: boolean
    - isOnline: boolean
    - status: string (available/busy/offline/in_class)
    - verified: boolean
    - subjects: array
    - hourlyRate: number
    - reviews/
        {reviewId}/
          - rating: number
          - comment: string

studentProfiles/
  {uid}/
    - grade: string
    - preferences: map

bookings/
  {bookingId}/
    - studentUid: string
    - tutorUid: string
    - status: string (pending/accepted/rejected/in_progress/completed)
    - subject: string
    - scheduledTime: timestamp
    - startTime: timestamp
    - endTime: timestamp
    - messages/
        {messageId}/
          - text: string
          - senderUid: string

verificationRequests/
  {requestId}/
    - tutorUid: string
    - status: string (pending/approved/rejected)
    - documents: array
```

## 📋 Available Scripts

```bash
# Run tests
flutter test

# Run with specific device
flutter run -t lib/main_student.dart -d "iPhone 17 Pro"

# Build for release (iOS)
flutter build ios --release

# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format lib/

# iOS pod rebuild (if needed)
cd ios && pod install && cd ..
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/repositories/booking_repository_test.dart
```

See `UNIT_TESTING_INVENTORY.md` for detailed test coverage and `SYSTEM_TESTING_PLAN.md` for manual test cases.

## 🔒 Security

- Firebase Security Rules enforced for all collections
- Role-based access control (RBAC)
- File upload validation (size, type)
- Input sanitization
- Secure authentication with Firebase Auth

**⚠️ Important**: 
- Never commit Firebase configuration files
- Never commit API keys or secrets
- Never commit `.env` files with credentials

## 📱 Supported Platforms

- ✅ iOS 13.0+
- 🚧 Android (coming soon)
- ❌ Web (not planned)
- ❌ Desktop (not planned)

## 🤝 Contributing

This is an educational project. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

Copyright © 2025 QuickTutor. All rights reserved.

This project is for educational purposes only.

## 📞 Support

For issues or questions, please open a GitHub issue.

## 🗺️ Roadmap

- [ ] Android support
- [ ] Video call integration
- [ ] Payment gateway integration (Stripe/PayPal)
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Tutor availability calendar
- [ ] Advanced search filters
- [ ] Student progress tracking
- [ ] Analytics dashboard
- [ ] Email notifications

## 📚 Documentation

- [System Testing Plan](SYSTEM_TESTING_PLAN.md) - 131 manual test cases
- [Unit Testing Inventory](UNIT_TESTING_INVENTORY.md) - Test coverage analysis
- [Firebase Initialization Audit](FIREBASE_INIT_AUDIT.md) - Architecture documentation
- [Quick Commands](QUICK_COMMANDS.md) - Development commands reference

## 🎓 Learning Resources

This project demonstrates:
- Flutter best practices
- Firebase integration patterns
- Repository pattern implementation
- Role-based access control
- Real-time data synchronization
- Push notification handling
- File upload management
- Material 3 design

## 🏆 Key Features Implemented

### Authentication & Authorization
- Email/password authentication
- Role-based routing (Student/Tutor/Admin)
- Profile management per role

### Tutor Management
- Document verification workflow
- Online/offline status with auto-busy
- Earnings tracking
- Review system

### Booking System
- Real-time booking requests
- Status transitions (pending → accepted → in progress → completed)
- Booking history with filters

### Communication
- In-app chat with file attachments
- Push notifications
- Real-time message synchronization

### Admin Tools
- Tutor verification approval
- User management (warn/ban)
- Platform monitoring

---

**Built with ❤️ using Flutter and Firebase**

*Last updated: November 14, 2025*
