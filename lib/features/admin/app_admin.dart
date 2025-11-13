import 'package:flutter/material.dart';

import '../../core/app_routes.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickTutor Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
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
      home: const _AdminBootstrap(),
    );
  }
}

class _AdminBootstrap extends StatelessWidget {
  const _AdminBootstrap();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Admin boots OK')));
  }
}
