import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageRepo = MessageRepository();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _bookingSubscription;
  Map<String, dynamic>? _bookingData;
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _classCompletionTriggered = false;
  bool _startingClass = false;
  String? _otherUserNameOverride;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    _messageRepo.markMessagesAsRead(widget.bookingId);
    _listenToBooking();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _bookingSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _messageRepo.sendMessage(bookingId: widget.bookingId, text: text);

    _textController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _listenToBooking() {
    _bookingSubscription = FirebaseFirestore.instance
        .doc('bookings/${widget.bookingId}')
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.data();
          if (!mounted) return;

          String? overrideName;
          if (data != null) {
            final tutorId = data['tutorId'];
            final studentId = data['studentId'];
            final tutorName = (data['tutorName'] as String?)?.trim();
            final studentName = (data['studentName'] as String?)?.trim();
            if (tutorId == _currentUserId && studentName != null) {
              overrideName = studentName;
            } else if (studentId == _currentUserId && tutorName != null) {
              overrideName = tutorName;
            }
          }

          setState(() {
            _bookingData = data;
            if (overrideName != null && overrideName.isNotEmpty) {
              _otherUserNameOverride = overrideName;
            }
          });
          _setupTimer();
        });
  }

  void _setupTimer() {
    _countdownTimer?.cancel();
    final data = _bookingData;
    if (data == null) {
      setState(() => _timeRemaining = null);
      return;
    }

    final Timestamp? startTs = data['classStartAt'] as Timestamp?;
    if (startTs == null) {
      setState(() => _timeRemaining = null);
      return;
    }

    final int duration =
        (data['classDurationMin'] ?? data['minutes'] ?? 30) as int;
    final int bufferBefore = (data['classBufferBeforeMin'] ?? 5) as int;
    final int bufferAfter = (data['classBufferAfterMin'] ?? 5) as int;
    final totalMinutes = duration + bufferBefore + bufferAfter;
    final end = startTs.toDate().add(Duration(minutes: totalMinutes));

    void tick() {
      final now = DateTime.now();
      if (!mounted) return;
      if (now.isAfter(end)) {
        _countdownTimer?.cancel();
        if (_timeRemaining != Duration.zero) {
          setState(() => _timeRemaining = Duration.zero);
        }
        unawaited(_completeClassIfNeeded(end));
      } else {
        setState(() => _timeRemaining = end.difference(now));
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _startClass() async {
    if (_bookingData == null || !_isTutor || _startingClass) return;
    setState(() => _startingClass = true);

    try {
      final data = _bookingData!;
      final now = DateTime.now();
      final int duration = (data['minutes'] ?? 30) as int;
      final int bufferBefore = (data['classBufferBeforeMin'] ?? 5) as int;
      final int bufferAfter = (data['classBufferAfterMin'] ?? 5) as int;
      final totalMinutes = duration + bufferBefore + bufferAfter;
      final end = now.add(Duration(minutes: totalMinutes));

      final bookingRef = FirebaseFirestore.instance.doc(
        'bookings/${widget.bookingId}',
      );
      await bookingRef.set({
        'status': 'in_progress',
        'classStartAt': Timestamp.fromDate(now),
        'classDurationMin': duration,
        'classBufferBeforeMin': bufferBefore,
        'classBufferAfterMin': bufferAfter,
        'classEndAt': Timestamp.fromDate(end),
      }, SetOptions(merge: true));

      final sessionRef = FirebaseFirestore.instance
          .collection('classSessions')
          .doc(widget.bookingId);
      await sessionRef.set({
        'sessionId': widget.bookingId,
        'bookingId': widget.bookingId,
        'tutorId': data['tutorId'],
        'tutorName': data['tutorName'],
        'studentId': data['studentId'],
        'studentName': data['studentName'],
        'subject': data['subject'],
        'startAt': Timestamp.fromDate(now),
        'endAt': Timestamp.fromDate(end),
        'durationMin': duration,
        'bufferBeforeMin': bufferBefore,
        'bufferAfterMin': bufferAfter,
        'price': data['price'],
        'status': 'in_progress',
      }, SetOptions(merge: true));

      await _messageRepo.sendMessage(
        bookingId: widget.bookingId,
        text:
            'I\'ve started the session. Share any materials or join via your preferred meeting link.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingClass = false);
    }
  }

  Future<void> _completeClassIfNeeded(DateTime endTime) async {
    if (_classCompletionTriggered) return;
    final data = _bookingData;
    if (data == null) return;
    final status = data['status'] as String? ?? '';
    if (status == 'completed') {
      _classCompletionTriggered = true;
      return;
    }

    _classCompletionTriggered = true;

    final bookingRef = FirebaseFirestore.instance.doc(
      'bookings/${widget.bookingId}',
    );
    await bookingRef.set({
      'status': 'completed',
      'classCompletedAt': Timestamp.fromDate(endTime),
    }, SetOptions(merge: true));

    final sessionRef = FirebaseFirestore.instance
        .collection('classSessions')
        .doc(widget.bookingId);
    await sessionRef.set({
      'status': 'completed',
      'endAt': Timestamp.fromDate(endTime),
    }, SetOptions(merge: true));
  }

  Widget _buildSessionBanner() {
    final data = _bookingData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final status = (data['status'] as String?) ?? 'pending';
    final Timestamp? startTs = data['classStartAt'] as Timestamp?;
    final int duration =
        (data['classDurationMin'] ?? data['minutes'] ?? 30) as int;
    final int bufferBefore = (data['classBufferBeforeMin'] ?? 5) as int;
    final int bufferAfter = (data['classBufferAfterMin'] ?? 5) as int;

    if (startTs == null) {
      if (_isTutor && (status == 'accepted' || status == 'paid')) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ready to start the class?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This session includes $duration minutes plus a 5-minute buffer before and after.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _startingClass ? null : _startClass,
                    icon: _startingClass
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Start Class'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.hourglass_bottom, color: Colors.orange),
              title: const Text('Waiting for tutor to start the class'),
              subtitle: Text(
                'You\'ll see a live timer once the session begins. Each class has a 5-minute buffer before and after.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
        );
      }
    }

    final start = startTs.toDate();
    final totalMinutes = duration + bufferBefore + bufferAfter;
    final end = start.add(Duration(minutes: totalMinutes));
    final classBegin = start.add(Duration(minutes: bufferBefore));
    final classEnd = classBegin.add(Duration(minutes: duration));
    final now = DateTime.now();

    String phase;
    Color phaseColor;
    if (now.isBefore(classBegin)) {
      phase = 'Warm-up buffer (5 min)';
      phaseColor = Colors.orange;
    } else if (now.isBefore(classEnd)) {
      phase = 'Class in session';
      phaseColor = Colors.green;
    } else if (now.isBefore(end)) {
      phase = 'Wrap-up buffer (5 min)';
      phaseColor = Colors.blueGrey;
    } else {
      phase = 'Session completed';
      phaseColor = Colors.grey;
    }

    final displayTime = _timeRemaining != null
        ? _formatDuration(_timeRemaining!)
        : '--:--';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 0,
        color: phaseColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase,
                style: TextStyle(
                  color: phaseColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time remaining in session window: $displayTime',
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Includes 5-minute buffers before and after, with $duration-minute class time.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return '00:00';
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _isTutor =>
      _bookingData != null && _bookingData!['tutorId'] == _currentUserId;

  bool get _isStudent =>
      _bookingData != null && _bookingData!['studentId'] == _currentUserId;

  String get _chatPartnerName {
    if (_otherUserNameOverride != null && _otherUserNameOverride!.isNotEmpty) {
      return _otherUserNameOverride!;
    }
    if (_isTutor) {
      return (_bookingData?['studentName'] as String?)?.trim() ??
          widget.otherUserName;
    }
    if (_isStudent) {
      return (_bookingData?['tutorName'] as String?)?.trim() ??
          widget.otherUserName;
    }
    return widget.otherUserName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chatPartnerName), centerTitle: true),
      body: Column(
        children: [
          _buildSessionBanner(),
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messageRepo.getBookingMessages(widget.bookingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final senderDisplay = (message.senderName.trim().isNotEmpty)
                        ? message.senderName
                        : (isMe ? 'You' : widget.otherUserName);
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                      message.ts,
                    );

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  senderDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
