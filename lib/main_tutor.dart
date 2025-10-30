import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_routes.dart';
import 'theme/tutor_theme.dart';
import 'features/gates/tutor_gate.dart';
import 'features/tutor/shell/tutor_shell.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push/push_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (d) => MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Error: ${d.exceptionAsString()}')),
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Register background message handler (must be top-level/entry-point)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // iOS: show notifications when app is foregrounded
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const TutorOnlyApp());
}

class TutorOnlyApp extends StatelessWidget {
  const TutorOnlyApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: tutorTheme,
    routes: Routes.map(),
    home: const TutorGate(child: TutorShell()),
  );
}
