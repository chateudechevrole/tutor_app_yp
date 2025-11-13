import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable model representing a student's profile preferences
class StudentProfile {
  final String grade;
  final List<String> subjects;
  final List<String> languages;
  final StudentAvailability availability;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentProfile({
    required this.grade,
    required this.subjects,
    required this.languages,
    required this.availability,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor with sensible defaults
  factory StudentProfile.defaults() => StudentProfile(
        grade: 'Year 5',
        subjects: const ['Math', 'English'],
        languages: const ['EN'],
        availability: StudentAvailability.defaults(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      grade: json['grade'] as String? ?? 'Year 5',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['Math', 'English'],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['EN'],
      availability: json['availability'] != null
          ? StudentAvailability.fromJson(
              json['availability'] as Map<String, dynamic>)
          : StudentAvailability.defaults(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'subjects': subjects,
      'languages': languages,
      'availability': availability.toJson(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudentProfile copyWith({
    String? grade,
    List<String>? subjects,
    List<String>? languages,
    StudentAvailability? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      grade: grade ?? this.grade,
      subjects: subjects ?? this.subjects,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Student's availability preferences
class StudentAvailability {
  final bool afterSchool;
  final bool evening;
  final bool weekend;

  const StudentAvailability({
    required this.afterSchool,
    required this.evening,
    required this.weekend,
  });

  factory StudentAvailability.defaults() => const StudentAvailability(
        afterSchool: true,
        evening: false,
        weekend: true,
      );

  factory StudentAvailability.fromJson(Map<String, dynamic> json) {
    return StudentAvailability(
      afterSchool: json['afterSchool'] as bool? ?? true,
      evening: json['evening'] as bool? ?? false,
      weekend: json['weekend'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'afterSchool': afterSchool,
      'evening': evening,
      'weekend': weekend,
    };
  }

  StudentAvailability copyWith({
    bool? afterSchool,
    bool? evening,
    bool? weekend,
  }) {
    return StudentAvailability(
      afterSchool: afterSchool ?? this.afterSchool,
      evening: evening ?? this.evening,
      weekend: weekend ?? this.weekend,
    );
  }
}
