import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Singleton Future that ensures Firebase is initialized only once.
final firebaseReady = _initFirebase();

Future<FirebaseApp> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  return Firebase.app();
}
