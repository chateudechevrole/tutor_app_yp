class Booking {
  final String id;
  final String studentId;
  final String tutorId;
  final String subject;
  final int minutes;
  final String status; // pending | paid | accepted | completed | cancelled
  final DateTime? createdAt;
  final DateTime? startAt;
  final num? price;
  final String? studentName;
  final String? tutorName;
  
  Booking({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.subject,
    required this.minutes,
    required this.status,
    this.createdAt,
    this.startAt,
    this.price,
    this.studentName,
    this.tutorName,
  });
  
  factory Booking.fromMap(String id, Map<String, dynamic> d) => Booking(
    id: id,
    studentId: d['studentId'],
    tutorId: d['tutorId'],
    subject: d['subject'] ?? '',
    minutes: d['minutes'] ?? 30,
    status: d['status'] ?? 'pending',
    createdAt: d['createdAt'] != null 
        ? (d['createdAt'] as dynamic).toDate() 
        : null,
    startAt: d['startAt'] != null 
        ? (d['startAt'] as dynamic).toDate() 
        : null,
    price: d['price'],
    studentName: d['studentName'],
    tutorName: d['tutorName'],
  );
  
  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'tutorId': tutorId,
    'subject': subject,
    'minutes': minutes,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt,
    if (startAt != null) 'startAt': startAt,
    if (price != null) 'price': price,
    if (studentName != null) 'studentName': studentName,
    if (tutorName != null) 'tutorName': tutorName,
  };
  
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted' || status == 'paid';
}
