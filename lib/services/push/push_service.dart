import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing push notifications
class PushService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  PushService() {
    _messaging.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        dev.log('⚠️ Token refresh skipped: no authenticated user');
        return;
      }

      try {
        await _saveToken(uid, token);
        dev.log('✅ Refreshed FCM token saved for $uid');
      } catch (e) {
        dev.log('❌ Error saving refreshed token: $e');
      }
    });
  }

  /// Request notification permissions and save FCM token to Firestore
  Future<void> requestPermissionsAndSaveToken() async {
    try {
      // Request permissions (iOS will show dialog, Android 13+ handled by manifest)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      dev.log('🔔 Notification permission status: ${settings.authorizationStatus}');

      // Get token and save to user document for targeted notifications
      final token = await _messaging.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null && token != null) {
        dev.log('✅ FCM Token obtained: ${token.substring(0, 20)}...');

        await _saveToken(uid, token);
      } else {
        dev.log('⚠️ Could not save FCM token: uid=$uid, tokenPresent=${token != null}');
      }
    } catch (e) {
      dev.log('❌ Error in requestPermissionsAndSaveToken: $e');
    }
  }

  /// Remove FCM token from Firestore on sign-out
  Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null && token != null) {
        await _db.collection('users').doc(uid).set(
          {
            'fcmTokens': FieldValue.arrayRemove([token]),
          },
          SetOptions(merge: true),
        );
        dev.log('✅ FCM token removed from Firestore');
      }
    } catch (e) {
      dev.log('❌ Error removing FCM token: $e');
    }
  }

  /// Listen to foreground messages and handle notification taps
  void listenForegroundMessages({
    void Function(RemoteMessage)? onMessage,
    void Function(RemoteMessage)? onMessageOpenedApp,
  }) {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      dev.log('🔔 Foreground message: ${message.notification?.title}');
      dev.log('   Data: ${message.data}');

      if (onMessage != null) {
        onMessage(message);
      }
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      dev.log('🔔 Notification opened: ${message.notification?.title}');
      dev.log('   Data: ${message.data}');

      if (onMessageOpenedApp != null) {
        onMessageOpenedApp(message);
      }
    });
  }

  /// Get initial message if app was launched from notification
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  Future<void> _saveToken(String uid, String token) {
    return _db.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
