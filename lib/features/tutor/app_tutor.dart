import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/app_routes.dart';
import '../../firebase_options.dart';
import '../../theme/tutor_theme.dart';
import '../../services/push/push_background.dart';
import '../gates/tutor_gate.dart';
import 'shell/tutor_shell.dart';

class TutorApp extends StatefulWidget {
  const TutorApp({super.key});

  @override
  State<TutorApp> createState() => _TutorAppState();
}

class _TutorAppState extends State<TutorApp> {
  bool _messagingConfigured = false;

  @override
  void initState() {
    super.initState();
    _logFirebaseConfig();
    _configureMessaging();
  }

  void _logFirebaseConfig() {
    debugPrint(
      '🔥 Firebase Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
    debugPrint(
      '🔥 Firebase App ID: ${DefaultFirebaseOptions.currentPlatform.appId}',
    );
    debugPrint(
      '🔥 Firebase Storage Bucket: ${DefaultFirebaseOptions.currentPlatform.storageBucket}',
    );
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
      theme: tutorTheme,
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
      home: const TutorGate(child: TutorShell()),
    );
  }
}
