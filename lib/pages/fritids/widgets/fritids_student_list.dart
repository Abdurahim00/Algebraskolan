import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../provider/fritids_provider.dart';
import '../../../domain/models/pass_type.dart';
import 'fritids_student_card.dart';

class FritidsStudentList extends StatelessWidget {
  const FritidsStudentList({super.key});

  bool _isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  @override
  Widget build(BuildContext context) {
    final fritidsProvider = context.watch<FritidsProvider>();
    final students = fritidsProvider.students;
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;
    double baseFontSize = _isTablet(context) ? 18 : fontSize;

    if (fritidsProvider.selectedGroup == null) {
      return Expanded(
        flex: 6,
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0, top: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Center(
                child: Text(
                  'Välj en grupp',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      flex: 6,
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, bottom: 10.0, top: 30.0, right: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // "Välj alla" button
            TextButton(
              onPressed: () {
                if (fritidsProvider.selectedStudents.isEmpty) {
                  fritidsProvider.selectAllStudents();
                } else {
                  fritidsProvider.deselectAllStudents();
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.all(fontSize * 0.5),
                alignment: Alignment.centerLeft,
              ),
              child: AutoSizeText(
                fritidsProvider.selectedStudents.isEmpty
                    ? "Välj alla >"
                    : "Avvälj alla >",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: baseFontSize,
                  color: fritidsProvider.selectedStudents.isEmpty
                      ? Colors.blue
                      : const Color.fromRGBO(245, 142, 11, 1),
                ),
                minFontSize: 12,
                maxLines: 1,
              ),
            ),
            // Horizontal scrolling student cards
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Row(
                  children: students.map((student) {
                    return FritidsStudentCard(student: student);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
