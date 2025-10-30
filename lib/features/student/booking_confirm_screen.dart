import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/booking_repository.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});
  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  int mins = 30;
  final subject = TextEditingController(text: 'English');
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    subject.dispose();
    noteCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext c) {
    final tutorId = ModalRoute.of(c)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            DropdownButton<int>(
              value: mins,
              items: const [30, 45, 60]
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e, child: Text('$e minutes')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => mins = v ?? 30),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note for tutor (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final price = _calculatePrice(mins);
                await BookingRepo().createBooking(
                  studentId: uid,
                  tutorId: tutorId,
                  subject: subject.text,
                  minutes: mins,
                  price: price,
                  message: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
                if (!mounted) return;
                final threadId = '${uid}_$tutorId';
                Navigator.pushReplacementNamed(
                  context,
                  '/student/chat',
                  arguments: threadId,
                );
              },
              child: const Text('Pay (Simulated) & Go to Chat'),
            ),
          ],
        ),
      ),
    );
  }
  int _calculatePrice(int minutes) {
    final blocks = (minutes / 30).ceil();
    return blocks * 10 + 2;
  }
}
