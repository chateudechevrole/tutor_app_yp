import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/app_routes.dart';
import '../../theme/student_theme.dart';
import '../../services/push/push_background.dart';
import '../gates/student_gate.dart';
import 'shell/student_shell.dart';

class StudentApp extends StatefulWidget {
  const StudentApp({super.key});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  bool _messagingConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureMessaging();
  }

  void _configureMessaging() {
    if (_messagingConfigured) return;
    _messagingConfigured = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    Future.microtask(() async {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: studentTheme,
      routes: Routes.map(),
      onGenerateRoute: Routes.onGenerateRoute,
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
      home: const StudentGate(child: StudentShell()),
    );
  }
}
