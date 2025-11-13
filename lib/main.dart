import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/bootstrap.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_picker_screen.dart';
import 'features/tutor/verify_upload_screen.dart';
import 'features/tutor/tutor_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/auth/landing_screen.dart';
import 'features/student/student_home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push/push_background.dart';

late final FirebaseAnalytics analytics;
// Guard to avoid LateInitializationError in tests where bootstrap isn't run
bool _analyticsReady = false;

Future<void> main() async {
  await bootstrap(() {
    _postBootstrapInit();
    return const QuickTutorApp();
  });
}

void _postBootstrapInit() {
  analytics = FirebaseAnalytics.instance;
  _analyticsReady = true;
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  Future.microtask(() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  });
}

class QuickTutorApp extends StatelessWidget {
  const QuickTutorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routes: Routes.map(),
      home: const LandingScreen(),
      navigatorObservers:
          _analyticsReady ? [FirebaseAnalyticsObserver(analytics: analytics)] : const [],
      onGenerateRoute: (settings) => null,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Route not found')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No route for: ${settings.name}'),
          ),
        ),
      ),
      builder: (context, child) {
        ErrorWidget.builder = (details) => Material(
          child: Center(
            child: Text('UI error: ${details.exceptionAsString()}'),
          ),
        );
        return child!;
      },
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
            final role = d['role'] ?? '';

            // If role is missing or empty, show role picker
            if (role.isEmpty) {
              return const RolePickerScreen();
            }

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
