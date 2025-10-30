import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_paths.dart';
import '../data/models/user_model.dart';
import 'push/push_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _pushService = PushService();

  Stream<User?> authState() => _auth.authStateChanges();

  Future<AppUser?> currentUserDoc() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final snap = await _db.doc(FP.users(u.uid)).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(u.uid, snap.data()!);
  }

  Future<UserCredential> signUp(
    String email,
    String pass, {
    String displayName = '',
    String role = 'student',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: pass,
    );
    await _db.doc(FP.users(cred.user!.uid)).set({
      'email': email,
      'role': role,
      'tutorVerified': false,
      'displayName': displayName.isEmpty ? 'User' : displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return cred;
  }

  Future<UserCredential> signIn(String email, String pass) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: pass,
    );
    final u = cred.user;
    if (u != null) {
      await _db.doc(FP.users(u.uid)).set({
        'email': u.email,
        'displayName': u.displayName ?? 'User',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Re-enable push: request permissions, save token, and start listeners
      await _pushService.requestPermissionsAndSaveToken();
      _pushService.listenForegroundMessages();
    }
    return cred;
  }

  Future<void> signOut() async {
    // Remove token on sign out
    await _pushService.removeToken();
    await _auth.signOut();
  }
}
