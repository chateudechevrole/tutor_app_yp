import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/tutor_theme.dart';
import '../../../widgets/status_pill.dart';

class EarningsPayoutScreen extends StatefulWidget {
  const EarningsPayoutScreen({super.key});

  @override
  State<EarningsPayoutScreen> createState() => _EarningsPayoutScreenState();
}

class _EarningsPayoutScreenState extends State<EarningsPayoutScreen> {
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  bool _savingBankInfo = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    super.dispose();
  }

  Future<void> _loadBankInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.doc('users/$uid').get();
    final bankInfo = doc.data()?['bankInfo'] as Map<String, dynamic>?;

    if (bankInfo != null && mounted) {
      setState(() {
        _accountHolderController.text = bankInfo['accountHolder'] ?? '';
        _bankNameController.text = bankInfo['bankName'] ?? '';
        _accountNoController.text = bankInfo['accountNo'] ?? '';
      });
    }
  }

  Future<void> _saveBankInfo() async {
    setState(() => _savingBankInfo = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'bankInfo': {
          'accountHolder': _accountHolderController.text,
          'bankName': _bankNameController.text,
          'accountNo': _accountNoController.text,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank info saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingBankInfo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Earnings & Payout'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classSessions')
              .where('tutorId', isEqualTo: uid)
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, sessionsSnapshot) {
            if (sessionsSnapshot.hasError) {
              final isPermissionError = sessionsSnapshot.error.toString().contains('permission-denied');
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
                          ? 'You don\'t have access to view earnings'
                          : 'Unable to load earnings data',
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

            if (!sessionsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = sessionsSnapshot.data!.docs;

            final lifetime = _calculateEarnings(sessions, null);
            final thisMonth = _calculateEarnings(
              sessions,
              DateTime.now().subtract(const Duration(days: 30)),
            );
            final last7Days = _calculateEarnings(
              sessions,
              DateTime.now().subtract(const Duration(days: 7)),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Earnings Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildEarningCard(
                        'Lifetime',
                        lifetime,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEarningCard(
                        'This Month',
                        thisMonth,
                        Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEarningCard(
                  'Last 7 Days',
                  last7Days,
                  Icons.date_range,
                  fullWidth: true,
                ),

                const SizedBox(height: 32),

                // Payouts Section
                const Text(
                  'Payouts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPayoutsSection(uid),

                const SizedBox(height: 32),

                // Bank Info Section
                const Text(
                  'Bank Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBankInfoForm(),
              ],
            );
          },
        ),
      ),
    );
  }

  double _calculateEarnings(List<QueryDocumentSnapshot> sessions, DateTime? since) {
    return sessions.where((doc) {
      if (since == null) return true;
      final startAt = ((doc.data() as Map)['startAt'] as Timestamp?)?.toDate();
      return startAt != null && startAt.isAfter(since);
    }).fold(0.0, (sum, doc) {
      final price = ((doc.data() as Map)['price'] ?? 0).toDouble();
      return sum + price;
    });
  }

  Widget _buildEarningCard(String label, double amount, IconData icon,
      {bool fullWidth = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: kPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: fullWidth ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsSection(String uid) {
    // Debug: Print the query path being used
    debugPrint('🔍 Payouts Query: collectionGroup("payouts").where("tutorId", isEqualTo: "$uid").orderBy("createdAt", descending: true)');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('payouts')
          .where('tutorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Payouts Error: ${snapshot.error}');
          final isPermissionError = snapshot.error.toString().contains('permission-denied');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError 
                      ? 'Permission Denied'
                      : 'Error loading payouts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionError
                      ? 'You don\'t have access to view payouts'
                      : 'Unable to load payout history',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
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

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final payouts = snapshot.data!.docs;
        
        // Debug: Log found payouts with their document paths
        debugPrint('✅ Found ${payouts.length} payout(s)');
        for (var doc in payouts) {
          debugPrint('   📄 Document path: ${doc.reference.path}');
        }

        if (payouts.isEmpty) {
          debugPrint('📭 No payouts found for tutor: $uid');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No records yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payout history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: payouts.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] ?? 0).toDouble();
              final status = data['status'] ?? 'processing';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.payment, color: kPrimary, size: 20),
                ),
                title: Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: createdAt != null
                    ? Text(_formatDate(createdAt))
                    : null,
                trailing: StatusPill(status: status, small: true),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBankInfoForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountNoController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savingBankInfo ? null : _saveBankInfo,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _savingBankInfo
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Bank Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
