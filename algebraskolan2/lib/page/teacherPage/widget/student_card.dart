import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double yOffset = screenHeight * 0.01;
    double verticalPadding = screenHeight * 0.01;
    double horizontalPadding = screenWidth * 0.01;

    return GestureDetector(
      onTap: () => studentProvider.toggleSelection(student),
      child: ValueListenableBuilder<bool>(
        valueListenable: isSelected,
        builder: (context, isSelectedValue, child) {
          return Transform.translate(
            offset: isSelectedValue ? Offset(0, -yOffset) : Offset.zero,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.30,
              margin: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: verticalPadding),
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
                      children: [
                        Mini_Coin_calculator(
                          studentNotifier: student,
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: ValueListenableBuilder<Student>(
                            valueListenable: student,
                            builder: (context, studentValue, _) {
                              return AutoSizeText(
                                studentValue.displayName,
                                style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                                minFontSize: 12,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
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
