import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateIcon extends StatelessWidget {
  final DateTime date;

  const DateIcon({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background color of the icon
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          Text(
            DateFormat('EE d MMM', 'sv_SE').format(date),
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
