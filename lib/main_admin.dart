import 'package:flutter/material.dart';
import 'core/firebase_singleton.dart';
import 'features/admin/app_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseReady;
  runApp(const AdminApp());
}
