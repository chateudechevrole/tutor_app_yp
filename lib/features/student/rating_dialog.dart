import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/tutor_repository.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.tutorId,
    required this.tutorName,
    required this.bookingId,
  });

  final String tutorId;
  final String tutorName;
  final String bookingId;

  static Future<bool?> show(
    BuildContext context, {
    required String tutorId,
    required String tutorName,
    required String bookingId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(
        tutorId: tutorId,
        tutorName: tutorName,
        bookingId: bookingId,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _repo = TutorRepo();
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Rate ${widget.tutorName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isActive = starIndex <= _rating;
              return IconButton(
                onPressed: () {
                  setState(() => _rating = starIndex);
                },
                icon: Icon(
                  isActive ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32,
                  color: isActive ? Colors.amber : Colors.grey[400],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Share your feedback (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please sign in to submit a review');
      return;
    }

    setState(() => _submitting = true);

    try {
      await _repo.submitReview(
        tutorId: widget.tutorId,
        studentId: user.uid,
        studentName: user.displayName ?? 'Student',
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('Failed to submit review: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
