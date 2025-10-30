import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/tutor/verify_upload_screen.dart';
import 'features/tutor/tutor_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/student/student_home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push/push_background.dart';

late final FirebaseAnalytics analytics;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Error: ${details.exceptionAsString()}')),
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  analytics = FirebaseAnalytics.instance;
  // Register background message handler (must be top-level/entry-point)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // iOS: show notifications when app is foregrounded
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(const QuickTutorApp());
}

class QuickTutorApp extends StatelessWidget {
  const QuickTutorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routes: Routes.map(),
      home: const RoleGate(),
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      onGenerateRoute: (settings) => null,
    );
  }
}

// Role gate: auth → fetch users/{uid}.role → route
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, s) {
        if (!s.hasData) return const LoginScreen();
        final uid = s.data!.uid;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.doc('users/$uid').get(),
          builder: (ctx2, ss) {
            if (!ss.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!ss.data!.exists) return const LoginScreen();
            final d = ss.data!.data() as Map<String, dynamic>;
            final role = d['role'] ?? 'student';
            final verified = d['tutorVerified'] ?? false;
            if (role == 'admin') return const AdminDashboardScreen();
            if (role == 'tutor') {
              return verified
                  ? const TutorDashboardScreen()
                  : const TutorVerifyScreen();
            }
            return const StudentHomeScreen();
          },
        );
      },
    );
  }
}
