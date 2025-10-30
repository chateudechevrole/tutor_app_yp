import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_routes.dart';
import 'theme/student_theme.dart';
import 'features/gates/student_gate.dart';
import 'features/student/shell/student_shell.dart';
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

  runApp(const StudentOnlyApp());
}

class StudentOnlyApp extends StatelessWidget {
  const StudentOnlyApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: studentTheme,
    routes: Routes.map(),
    onGenerateRoute: Routes.onGenerateRoute,
    home: const StudentGate(child: StudentShell()),
  );
}
