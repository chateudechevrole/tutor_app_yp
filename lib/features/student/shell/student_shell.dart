import 'package:flutter/material.dart';
import '../student_home_screen.dart';
import '../messages/student_messages_screen.dart';
import '../profile/student_profile_screen.dart';
import '../../../theme/student_theme.dart';
import '../../../services/push/push_service.dart';
import '../../../services/notification_service.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => StudentShellState();

  static StudentShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<StudentShellState>();
  }
}

class StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;
  final _pushService = PushService();
  final _notificationService = NotificationService();

  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPushNotifications();
    _initNotificationMonitoring();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _initNotificationMonitoring() async {
    // Wait a bit for context to be available
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _notificationService.startMonitoring(context);
    }
  }

  Future<void> _initPushNotifications() async {
    // Request permissions and save FCM token
    await _pushService.requestPermissionsAndSaveToken();

    // Listen to foreground messages
    _pushService.listenForegroundMessages(
      onMessage: (message) {
        debugPrint(
          '📱 Student app received notification: ${message.notification?.title}',
        );

        // Show in-app notification
        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (message.notification!.body != null)
                    Text(message.notification!.body!),
                ],
              ),
              backgroundColor: message.data['status'] == 'accepted'
                  ? Colors.green
                  : Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to Messages tab to see booking updates
                  setState(() => _currentIndex = 1);
                },
              ),
            ),
          );
        }
      },
      onMessageOpenedApp: (message) {
        debugPrint(
          '📱 Student opened notification: ${message.notification?.title}',
        );

        // Navigate to Messages tab when notification is tapped
        if (mounted) {
          setState(() => _currentIndex = 1);
        }
      },
    );

    // Check if app was opened from a notification
    final initialMessage = await _pushService.getInitialMessage();
    if (initialMessage != null && mounted) {
      debugPrint(
        '📱 App launched from notification: ${initialMessage.notification?.title}',
      );
      setState(() => _currentIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kStudentBg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentHomeScreen(),
          StudentMessagesScreen(),
          StudentProfileScreen(),
        ],
      ),
    );
  }
}
