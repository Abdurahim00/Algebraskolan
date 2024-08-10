import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  final Map<String, Object> classData;

  const ClassCard({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    // Get the current screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define a proportional width based on screen width
    double cardWidth = screenWidth * 0.15; // Card takes 22% of screen width
    double cardHeight =
        cardWidth * 0.8; // Adjust the height based on a 3:2 ratio

    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      width: cardWidth,
      height: cardHeight,
      child: AspectRatio(
        aspectRatio: 3 / 4, // Ensures consistent height-to-width ratio
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 3.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      "assets/images/${classData['image']}",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${classData["name"]}",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.apply(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
