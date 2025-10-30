import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  int _selectedMonth = DateTime.now().month;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, _selectedMonth, 1);
  }

  DateTime _getMonthEnd() {
    final now = DateTime.now();
    return DateTime(now.year, _selectedMonth + 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Records'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchText = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(_getMonthName(month)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('startAt', isGreaterThanOrEqualTo: _getMonthStart())
            .where('startAt', isLessThan: _getMonthEnd())
            .orderBy('startAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (_searchText.isNotEmpty) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              final subject = (data?['subject'] ?? '').toString().toLowerCase();
              final studentId = (data?['studentId'] ?? '')
                  .toString()
                  .toLowerCase();
              final tutorId = (data?['tutorId'] ?? '').toString().toLowerCase();
              return subject.contains(_searchText) ||
                  studentId.contains(_searchText) ||
                  tutorId.contains(_searchText);
            }).toList();
          }

          if (docs.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Booking ID')),
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Tutor')),
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Grade')),
                  DataColumn(label: Text('Date/Time')),
                  DataColumn(label: Text('Status')),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final bookingId = doc.id;
                  final studentId = data?['studentId'] ?? 'N/A';
                  final tutorId = data?['tutorId'] ?? 'N/A';
                  final subject = data?['subject'] ?? 'N/A';
                  final grade = data?['grade'] ?? 'N/A';
                  final startAt = data?['startAt'] as Timestamp?;
                  final status = data?['status'] ?? 'unknown';

                  return DataRow(
                    cells: [
                      DataCell(Text(bookingId.substring(0, 8))),
                      DataCell(Text(studentId.toString())),
                      DataCell(Text(tutorId.toString())),
                      DataCell(Text(subject.toString())),
                      DataCell(Text(grade.toString())),
                      DataCell(
                        Text(
                          startAt != null
                              ? _formatDateTime(startAt.toDate())
                              : 'N/A',
                        ),
                      ),
                      DataCell(_buildStatusPill(status.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'done':
        color = Colors.green;
        break;
      case 'booked':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
