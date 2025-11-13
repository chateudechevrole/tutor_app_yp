import 'package:flutter/material.dart';
import 'core/firebase_singleton.dart';
import 'features/student/app_student.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseReady;
  runApp(const StudentApp());
}
