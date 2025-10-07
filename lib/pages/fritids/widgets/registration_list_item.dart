import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/fritids_pass_registration_model.dart';

class RegistrationListItem extends StatelessWidget {
  final FritidsPassRegistrationModel registration;

  const RegistrationListItem({
    super.key,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: registration.isReverted
              ? Colors.red[100]
              : _getPassTypeColor(registration.passType.displayName),
          child: Text(
            registration.passType.displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: registration.isReverted ? Colors.red : Colors.white,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                registration.studentName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: registration.isReverted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            Text(
              registration.group.displayName == 'Solen' ? '☀️' : '🌊',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${registration.group.displayName} - ${registration.passType.fullDisplayName}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Registrerad av ${registration.staffName} kl ${timeFormat.format(registration.timestamp)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            if (registration.isReverted)
              const Text(
                'ÅTERSTÄLLD',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              registration.isReverted
                  ? Icons.cancel
                  : Icons.check_circle,
              color: registration.isReverted ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 4),
            Text(
              '+${registration.algebronaAwarded}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: registration.isReverted ? Colors.red : Colors.green,
                decoration: registration.isReverted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPassTypeColor(String passType) {
    switch (passType) {
      case 'FM':
        return Colors.orange;
      case 'EM':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
