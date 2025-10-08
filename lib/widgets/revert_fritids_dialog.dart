import 'package:flutter/material.dart';
import '../domain/models/fritids_pass_registration_model.dart';

class RevertFritidsDialog extends StatelessWidget {
  final List<FritidsPassRegistrationModel> todayRegistrations;
  final Function(String registrationId) onRevert;

  const RevertFritidsDialog({
    Key? key,
    required this.todayRegistrations,
    required this.onRevert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (todayRegistrations.isEmpty) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Inga registreringar'),
          ],
        ),
        content: const Text(
          'Det finns inga registreringar idag att ångra.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.undo,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ångra registreringar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tryck på en registrering för att ångra den. Eleven får tillbaka sin plats och förlorar 1 algebrona.',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dagens registreringar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: ListView.builder(
                  itemCount: todayRegistrations.length,
                  itemBuilder: (context, index) {
                    final registration = todayRegistrations[index];
                    final timeStr =
                        '${registration.timestamp.hour.toString().padLeft(2, '0')}:${registration.timestamp.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        child: Text(
                          registration.studentName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(registration.studentName),
                      subtitle: Text(
                        '${registration.passType.displayName} • ${registration.group.displayName} • $timeStr',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRevert(registration.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ångra'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Stäng',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
