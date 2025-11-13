import 'dart:async';

import 'package:flutter/material.dart';

class LaunchErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stack;

  const LaunchErrorScreen(this.error, this.stack, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Launch error',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('$error', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  Text('${stack ?? ''}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LaunchSplash extends StatelessWidget {
  const LaunchSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

// Deprecated: Use firebaseReady from firebase_singleton.dart instead.
Future<void> ensureFirebaseInitialized() async {
  // No-op. Initialization is handled by firebaseReady singleton.
}

Future<void> bootstrap(Widget Function() buildApp) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LaunchSplash());

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await runZonedGuarded<Future<void>>(
    () async {
      await ensureFirebaseInitialized();
      runApp(buildApp());
    },
    (error, stack) {
      runApp(LaunchErrorScreen(error, stack));
    },
  );
}
