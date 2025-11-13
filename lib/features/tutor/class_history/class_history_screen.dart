import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/tutor_theme.dart';
import '../../../widgets/status_pill.dart';

class ClassHistoryScreen extends StatefulWidget {
  const ClassHistoryScreen({super.key});

  @override
  State<ClassHistoryScreen> createState() => _ClassHistoryScreenState();
}

class _ClassHistoryScreenState extends State<ClassHistoryScreen> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Class History'),
        ),
        body: Column(
          children: [
            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: kPrimary.withValues(alpha: 0.2),
                      checkmarkColor: kPrimary,
                      labelStyle: TextStyle(
                        color: isSelected ? kPrimary : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sessions List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getSessionsStream(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final isPermissionError = snapshot.error.toString().contains('permission-denied');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isPermissionError 
                                ? 'Permission Denied'
                                : 'Something went wrong',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPermissionError
                                ? 'You don\'t have access to view class history'
                                : 'Unable to load class history',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                setState(() {}); // Retry
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessions = snapshot.data!.docs;

                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No records yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your class history will appear here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final doc = sessions[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final studentName = data['studentName'] ?? 'Student';
                      final startAt = (data['startAt'] as Timestamp?)?.toDate();
                      final durationMin = data['durationMin'] ?? 0;
                      final price = (data['price'] ?? 0).toDouble();
                      final status = data['status'] ?? 'pending';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.calendar_today,
                              color: kPrimary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            studentName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            startAt != null
                                ? '${_formatDate(startAt)} • $durationMin min • RM ${price.toStringAsFixed(2)}'
                                : '$durationMin min • RM ${price.toStringAsFixed(2)}',
                          ),
                          trailing: StatusPill(status: status, small: true),
                          onTap: () => _showSessionDetail(context, data),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getSessionsStream(String uid) {
    var query = FirebaseFirestore.instance
        .collection('classSessions')
        .where('tutorId', isEqualTo: uid);

    // Apply status filter if needed
    if (_selectedFilter != 'All') {
      query = query.where(
        'status',
        isEqualTo: _selectedFilter.toLowerCase(),
      );
    }

    // Order by startAt
    query = query.orderBy('startAt', descending: true);

    return query.snapshots();
  }

  void _showSessionDetail(BuildContext context, Map<String, dynamic> data) {
    final studentName = data['studentName'] ?? 'Student';
    final startAt = (data['startAt'] as Timestamp?)?.toDate();
    final endAt = (data['endAt'] as Timestamp?)?.toDate();
    final durationMin = data['durationMin'] ?? 0;
    final price = (data['price'] ?? 0).toDouble();
    final status = data['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Student', studentName),
            if (startAt != null) ...[
              _buildDetailRow(
                'Start Time',
                _formatDateTime(startAt),
              ),
            ],
            if (endAt != null) ...[
              _buildDetailRow(
                'End Time',
                _formatTime(endAt),
              ),
            ],
            _buildDetailRow('Duration', '$durationMin minutes'),
            _buildDetailRow('Price', 'RM ${price.toStringAsFixed(2)}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final dateStr = _formatDate(date);
    final timeStr = _formatTime(date);
    return '$dateStr • $timeStr';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
