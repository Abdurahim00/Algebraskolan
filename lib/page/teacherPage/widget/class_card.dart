import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'coin_calculator.dart';

class ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const ClassCard({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Set maximum width limit
    const double maxCardWidth = 200.0; // Adjust as needed

    // Calculate card width with a limit
    double cardWidth = math.min(screenWidth * 0.25, maxCardWidth);

    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Coin_calculator(),
            Image.asset("assets/images/${classData['image']}"),
            const SizedBox(height: 10),
            Text(
              "${classData["name"]}",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.apply(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
