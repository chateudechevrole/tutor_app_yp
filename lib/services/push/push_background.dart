import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/bootstrap.dart';

/// Background message handler for Firebase Cloud Messaging
/// This runs in a separate isolate, so it needs its own Firebase initialization
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need other Firebase services here, ensure Firebase is initialized.
  await ensureFirebaseInitialized();
  dev.log('🔔 Background message received: ${message.messageId}');
  dev.log('   Data: ${message.data}');
  dev.log('   Notification: ${message.notification?.title ?? "No title"}');
}
