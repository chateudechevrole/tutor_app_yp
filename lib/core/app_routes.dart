import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/student/student_home_screen.dart';
import '../features/student/shell/student_shell.dart';
import '../features/student/profile/student_profile_screen.dart';
import '../features/student/tutor_search_screen.dart';
import '../features/student/tutor_profile_screen.dart';
import '../features/student/tutor_detail_screen.dart';
import '../features/student/booking_screens.dart';
import '../features/student/chat_screen.dart';
import '../features/tutor/verify_upload_screen.dart';
import '../features/tutor/tutor_dashboard_screen.dart';
import '../features/tutor/tutor_profile_edit_screen.dart';
import '../features/tutor/tutor_messages_screen.dart';
import '../features/tutor/tutor_login_screen.dart';
import '../features/tutor/tutor_waiting_screen.dart';
import '../features/tutor/tutor_chats_screen.dart';
import '../features/tutor/tutor_chat_screen.dart';
import '../features/tutor/tutor_bookings_screen.dart';
import '../features/tutor/tutor_booking_detail_screen.dart';
import '../features/tutor/shell/tutor_shell.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/verify_queue_screen.dart';
import '../features/admin/shell/admin_shell.dart';
import '../features/admin/account/admin_account_screen.dart';
import '../features/admin/users/admin_users_screen.dart';
import '../features/admin/verify/admin_verification_screen.dart';
import '../features/admin/verify/admin_verification_detail_screen.dart';
import '../features/admin/bookings/admin_bookings_screen.dart';
import '../features/admin/home/admin_home_screen.dart';
import '../main.dart' show RoleGate;

class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const roleGate = '/role-gate';
  static const studentShell = '/student/shell';
  static const studentHome = '/student/home';
  static const studentChat = '/student/chat';
  static const studentProfile = '/student/profile';
  static const tutorSearch = '/student/search';
  static const tutorProfile = '/student/tutor';
  static const tutorDetail = '/student/tutor-detail';
  static const bookingConfirm = '/student/booking-confirm';
  static const payment = '/student/payment';
  static const tutorShell = '/tutor/shell';
  static const tutorLogin = '/tutor/login';
  static const tutorVerify = '/tutor/verify';
  static const tutorWaiting = '/tutor/waiting';
  static const tutorDash = '/tutor/dashboard';
  static const tutorEdit = '/tutor/edit';
  static const tutorMsgs = '/tutor/messages';
  static const tutorChats = '/tutor/chats';
  static const tutorChat = '/tutor/chat';
  static const tutorBookings = '/tutor/bookings';
  static const tutorBookingDetail = '/tutor/booking-detail';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin';
  static const verifyQueue = '/admin/verify-queue';
  static const adminShell = '/admin/shell';
  static const adminHome = '/admin/home';
  static const adminAccount = '/admin/account';
  static const adminUsers = '/admin/users';
  static const adminVerify = '/admin/verify';
  static const adminVerifyDetail = '/admin/verify/detail';
  static const adminBookings = '/admin/bookings';

  static Map<String, WidgetBuilder> map() => {
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    roleGate: (_) => const RoleGate(),
    studentShell: (_) => const StudentShell(),
    studentHome: (_) => const StudentHomeScreen(),
    studentChat: (_) => const StudentChatScreen(),
    studentProfile: (_) => const StudentProfileScreen(),
    tutorSearch: (_) => const TutorSearchScreen(),
    tutorProfile: (_) => const TutorProfileScreen(),
    tutorShell: (_) => const TutorShell(),
    tutorLogin: (_) => const TutorLoginScreen(),
    tutorVerify: (_) => const TutorVerifyScreen(),
    tutorWaiting: (_) => const TutorWaitingScreen(),
    tutorDash: (_) => const TutorDashboardScreen(),
    tutorEdit: (_) => const TutorProfileEditScreen(),
    tutorMsgs: (_) => const TutorMessagesScreen(),
    tutorChats: (_) => const TutorChatsScreen(),
    tutorChat: (_) => const TutorChatScreen(),
    tutorBookings: (_) => const TutorBookingsScreen(),
    adminLogin: (_) => const AdminLoginScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    verifyQueue: (_) => const VerifyQueueScreen(),
    adminShell: (_) => const AdminShell(),
    adminHome: (_) => const AdminHomeScreen(),
    adminAccount: (_) => const AdminAccountScreen(),
    adminUsers: (_) => const AdminUsersScreen(),
    adminVerify: (_) => const AdminVerificationScreen(),
    adminBookings: (_) => const AdminBookingsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case tutorDetail:
        final tutorId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TutorDetailScreen(tutorId: tutorId),
        );
      case bookingConfirm:
        final tutorId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookingConfirmScreen(tutorId: tutorId),
        );
      case payment:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentGatewayScreen(
            tutorId: args['tutorId'] as String,
            amount: args['amount'] as double,
          ),
        );
      case adminVerifyDetail:
        final tutorId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AdminVerificationDetailScreen(tutorId: tutorId),
        );
      case tutorBookingDetail:
        final bookingId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TutorBookingDetailScreen(bookingId: bookingId),
        );
      default:
        final builder = map()[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
