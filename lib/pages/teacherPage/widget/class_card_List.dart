import 'package:flutter/material.dart';
import 'class_card.dart';

class ClassCardList extends StatelessWidget {
  final List<Map<String, Object>> classesData;

  const ClassCardList({super.key, required this.classesData});

  @override
  Widget build(BuildContext context) {
    // Get the current screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define the height based on card dimensions
    double cardWidth = screenWidth * 0.15; // Same as in ClassCard
    double containerHeight = cardWidth * 1.2; // Adjust the height accordingly

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: classesData.length,
        itemBuilder: (context, index) {
          return ClassCard(
            classData: classesData[index],
          );
        },
      ),
    );
  }
}
