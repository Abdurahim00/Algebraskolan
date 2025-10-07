import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:math' as math;
import '../../../provider/fritids_provider.dart';
import '../../../domain/models/student_model.dart';

class FritidsStudentCard extends StatelessWidget {
  final StudentModel student;

  const FritidsStudentCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final fritidsProvider = context.watch<FritidsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // EXACT same dimensions as teacher screen student card
    const double maxCardWidth = 170.0;
    const double maxImageSideLength = 80.0;
    const double maxFontSize = 18.0;

    double cardWidth = math.min(screenWidth * 0.30, maxCardWidth);
    double imageSideLength = math.min(cardWidth * 0.5, maxImageSideLength);
    double fontSize = math.min(screenWidth * 0.04, maxFontSize);

    double verticalPadding = math.min(screenHeight * 0.01, 10.0);
    double horizontalPadding = math.min(screenWidth * 0.01, 10.0);

    final bool hasFM = fritidsProvider.hasRegisteredForFM(student.uid);
    final bool hasEM = fritidsProvider.hasRegisteredForEM(student.uid);
    final bool canRegister =
        !fritidsProvider.hasRegisteredForCurrentPass(student.uid);
    final bool isSelected = fritidsProvider.selectedStudents.contains(student);
    final bool isRegistering = fritidsProvider.isRegistering;

    // Determine card color
    Color cardColor;
    if (!canRegister) {
      cardColor = Colors.green;
    } else if (isSelected) {
      cardColor = const Color.fromRGBO(245, 142, 11, 1); // Orange when selected
    } else if (isRegistering) {
      cardColor = Colors.grey;
    } else {
      cardColor = Colors.lightBlue;
    }

    return GestureDetector(
      onTap: canRegister && !isRegistering
          ? () {
              fritidsProvider.toggleStudentSelection(student);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        // Lift card when selected (smooth animation)
        transform: Matrix4.translationValues(
          0,
          isSelected ? -screenHeight * 0.01 : 0,
          0,
        ),
        width: cardWidth,
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: isSelected ? 6.0 : 2.0, // More shadow when selected
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
              // Profile image
              SizedBox(
                height: imageSideLength * 1.0,
                width: imageSideLength * 1.0,
                child: Image.asset(
                  "assets/images/profile5.png",
                  fit: BoxFit.scaleDown,
                ),
              ),
              const SizedBox(height: 5),
              // Student name
              Flexible(
                child: AutoSizeText(
                  student.displayName,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                  ),
                  minFontSize: 8,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 5),
                      // Pass badges (FM and EM)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPassBadge('FM', hasFM),
                          const SizedBox(width: 4),
                          _buildPassBadge('EM', hasEM),
                        ],
                      ),
                    ],
                  ),
                ),
                // Green checkmark when selected (orange card)
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                // Large checkmark overlay for already registered students (green card)
                if (!canRegister)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassBadge(String label, bool isChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: 12,
          ),
        ],
      ),
    );
  }
}
