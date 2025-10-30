class AppUser {
  final String uid;
  final String email;
  final String role; // student | tutor | admin
  final bool tutorVerified;
  final String displayName;
  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.tutorVerified,
    required this.displayName,
  });
  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
    uid: uid,
    email: d['email'] ?? '',
    role: d['role'] ?? 'student',
    tutorVerified: d['tutorVerified'] ?? false,
    displayName: d['displayName'] ?? '',
  );
  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
    'tutorVerified': tutorVerified,
    'displayName': displayName,
  };
}
