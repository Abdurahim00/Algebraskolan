import 'package:algebra/page/teacherPage/widget/student_card.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';

import '../../../provider/student_provider.dart';

class StudentListPart extends StatefulWidget {
  final TextTheme textTheme;

  const StudentListPart({
    Key? key,
    required this.textTheme,
  }) : super(key: key);

  @override
  State<StudentListPart> createState() => _StudentListPartState();
}

class _StudentListPartState extends State<StudentListPart> {
  @override
  void initState() {
    super.initState();
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    studentProvider.fetchStudents(studentProvider
        .selectedClass); // Fetch students using selectedClass from provider
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider =
        Provider.of<StudentProvider>(context); // Fetch the StudentProvider
    double fontSize = MediaQuery.of(context).size.width * 0.04;

    return Expanded(
      flex: 6,
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, bottom: 10.0, top: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                if (studentProvider.selectedStudents.isNotEmpty) {
                  studentProvider.handleDeselectAllStudents();
                } else {
                  studentProvider.handleSelectAllStudents();
                }
              },
              child: AutoSizeText(
                studentProvider.selectedStudents.isEmpty
                    ? "Välj alla >"
                    : "Avvälj alla >",
                style: TextStyle(
                  fontFamily:
                      'Montserrat', // Use the font family name you declared in pubspec.yaml
                  fontSize: fontSize,
                  color: studentProvider.selectedStudents.isEmpty
                      ? Colors.blue
                      : const Color.fromRGBO(245, 142, 11, 1),
                ),
                minFontSize: 12,
                maxLines: 1,
              ),
            ),
            // first singlechildscroll is for horizontal use, and the second is so i dont get bottom overflow
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  child: Row(
                    children: studentProvider.students.map((studentnotifier) {
                      return StudentCard(
                        student: studentnotifier,
                        selected: studentProvider.selectedStudents
                            .contains(studentnotifier),
                        onTap: () {
                          studentProvider
                              .toggleStudentSelection(studentnotifier);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
