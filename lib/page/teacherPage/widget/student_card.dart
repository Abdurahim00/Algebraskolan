import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../provider/student_provider.dart';
import '../../student.dart';
import 'coin_calculator.dart';

class StudentCard extends StatelessWidget {
  final ValueNotifier<Student> student;
  final ValueNotifier<bool> isSelected;
  final VoidCallback onTap;

  StudentCard({
    Key? key,
    required this.student,
    bool selected = false,
    required this.onTap,
  })  : isSelected = ValueNotifier<bool>(selected),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set maximum limits
    const double maxCardWidth = 170.0; // Maximum card width
    const double maxImageSideLength = 80.0; // Maximum image side length
    const double maxFontSize = 18.0; // Maximum font size

    // Calculate dimensions with limits
    double cardWidth = math.min(screenWidth * 0.30, maxCardWidth);
    double imageSideLength = math.min(cardWidth * 0.5, maxImageSideLength);
    double fontSize = math.min(screenWidth * 0.04, maxFontSize);

    double verticalPadding =
        math.min(screenHeight * 0.01, 10.0); // Example: max 10.0
    double horizontalPadding =
        math.min(screenWidth * 0.01, 10.0); // Example: max 10.0

    return GestureDetector(
      onTap: () => studentProvider.toggleSelection(student),
      child: ValueListenableBuilder<bool>(
        valueListenable: isSelected,
        builder: (context, isSelectedValue, child) {
          return Transform.translate(
            offset:
                isSelectedValue ? Offset(0, -screenHeight * 0.01) : Offset.zero,
            child: Container(
              width: cardWidth,
              margin: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Card(
                  color: isSelectedValue
                      ? const Color.fromRGBO(245, 142, 11, 1)
                      : Colors.lightBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isSelectedValue) ...[
                          SizedBox(
                            height: imageSideLength * 1.2,
                            width: imageSideLength * 1.2,
                            child: Image.asset(
                              "assets/images/profile5.png",
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (isSelectedValue) ...[
                          Mini_Coin_calculator(
                            studentNotifier: student,
                          ),
                        ],
                        Flexible(
                          child: AutoSizeText(
                            student.value.displayName,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: fontSize,
                            ),
                            minFontSize: 8,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
