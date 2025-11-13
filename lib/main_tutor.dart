import 'package:flutter/material.dart';
import 'core/firebase_singleton.dart';
import 'features/tutor/app_tutor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseReady;
  runApp(const TutorApp());
}
