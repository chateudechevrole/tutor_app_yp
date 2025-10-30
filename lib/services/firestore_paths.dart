class FP {
  static String users(String uid) => 'users/$uid';
  static String tutorProfiles(String uid) => 'tutorProfiles/$uid';
  static String verificationRequests(String uid) => 'verificationRequests/$uid';
  static String booking(String id) => 'bookings/$id';
  static String bookings() => 'bookings';
  static String chatThread(String threadId) => 'chats/$threadId';
  static String chatMessages(String threadId) => 'chats/$threadId/messages';
}
