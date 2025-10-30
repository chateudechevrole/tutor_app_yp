import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_routes.dart';
import '../../theme/student_theme.dart';

class BookingConfirmScreen extends StatelessWidget {
  final String tutorId;

  const BookingConfirmScreen({super.key, required this.tutorId});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: studentTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .doc('tutorProfiles/$tutorId')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('Tutor not found'));
            }

            return _buildContent(context, data);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> tutorData) {
    final displayName =
        tutorData['displayName'] ?? tutorData['email'] ?? 'Tutor';
    final photoUrl = tutorData['photoUrl'] as String?;
    final subjects = List<String>.from(tutorData['subjects'] ?? []);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tutor Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: kStudentDeep.withValues(alpha: 0.1),
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Icon(Icons.person, color: kStudentDeep)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subjects.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subjects.join(', '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Session Details
              const Text(
                'Session Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Duration', '45 minutes'),
              _buildDetailRow('Price', 'RM 30.00'),
              _buildDetailRow('Platform', 'Online (Video Call)'),
              const SizedBox(height: 24),

              // Terms
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Booking Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Payment is required to confirm booking\n'
                        '• Cancellations must be made 24h in advance\n'
                        '• Tutor will contact you to schedule the session',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.payment,
                  arguments: {'tutorId': tutorId, 'amount': 30.0},
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: kStudentDeep,
              ),
              child: const Text(
                'Confirm & Pay RM 30.00',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class PaymentGatewayScreen extends StatefulWidget {
  final String tutorId;
  final double amount;

  const PaymentGatewayScreen({
    super.key,
    required this.tutorId,
    required this.amount,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  bool _processing = false;

  Future<void> _processPayment() async {
    setState(() => _processing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Create booking record
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
    final bookingId = bookingRef.id;

    await bookingRef.set({
      'studentId': uid,
      'tutorId': widget.tutorId,
      'amount': widget.amount,
      'duration': 45,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'completed',
    });

    // Create in-app notification for tutor
    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.tutorId)
        .collection('items')
        .doc();

    await notifRef.set({
      'type': 'booking_created',
      'bookingId': bookingId,
      'fromUserId': uid,
      'title': 'New booking request',
      'body': 'A student just booked you. Tap to review.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (mounted) {
      setState(() => _processing = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Payment Successful!'),
            ],
          ),
          content: const Text(
            'Your booking has been confirmed. The tutor will contact you soon to schedule the session.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ); // Return to home
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: studentTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Card
              Card(
                color: kStudentDeep,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods (Placeholder)
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption('Credit/Debit Card', Icons.credit_card),
              _buildPaymentOption('Online Banking', Icons.account_balance),
              _buildPaymentOption('E-Wallet', Icons.account_balance_wallet),
              const Spacer(),

              // Process Button
              FilledButton(
                onPressed: _processing ? null : _processPayment,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: kStudentDeep,
                ),
                child: _processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Text(
                '🔒 Secure payment powered by QuickTutor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: kStudentDeep),
        title: Text(title),
        trailing: Radio(value: true, groupValue: true, onChanged: (_) {}),
      ),
    );
  }
}
