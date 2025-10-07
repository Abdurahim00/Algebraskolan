import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../provider/fritids_provider.dart';
import '../../../domain/models/fritids_group.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;
    double baseFontSize = _isTablet(context) ? 18 : fontSize;

    return Selector<FritidsProvider, ({
      FritidsGroup? selectedGroup,
      List students,
      List selectedStudents,
      bool isLoading,
    })>(
      selector: (_, provider) => (
        selectedGroup: provider.selectedGroup,
        students: provider.students,
        selectedStudents: provider.selectedStudents,
        isLoading: provider.isLoading,
      ),
      builder: (context, data, _) {
        final fritidsProvider = context.read<FritidsProvider>();

    if (data.selectedGroup == null) {
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
                if (data.selectedStudents.isEmpty) {
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
                data.selectedStudents.isEmpty
                    ? "Välj alla >"
                    : "Avvälj alla >",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: baseFontSize,
                  color: data.selectedStudents.isEmpty
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
                  children: data.students.map((student) {
                    // Wrap each card in RepaintBoundary for better performance
                    return RepaintBoundary(
                      child: FritidsStudentCard(student: student),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
