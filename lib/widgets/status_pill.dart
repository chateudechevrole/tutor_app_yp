import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  final String status;
  final bool small;

  const StatusPill({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return _StatusConfig(
          label: 'Completed',
          color: Colors.green,
        );
      case 'cancelled':
      case 'rejected':
        return _StatusConfig(
          label: 'Cancelled',
          color: Colors.red,
        );
      case 'no_show':
        return _StatusConfig(
          label: 'No Show',
          color: Colors.orange,
        );
      case 'pending':
      case 'paid':
        return _StatusConfig(
          label: 'Pending',
          color: Colors.orange,
        );
      case 'accepted':
        return _StatusConfig(
          label: 'Accepted',
          color: Colors.blue,
        );
      case 'processing':
        return _StatusConfig(
          label: 'Processing',
          color: Colors.blue,
        );
      case 'failed':
        return _StatusConfig(
          label: 'Failed',
          color: Colors.red,
        );
      default:
        return _StatusConfig(
          label: status,
          color: Colors.grey,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  _StatusConfig({required this.label, required this.color});
}
