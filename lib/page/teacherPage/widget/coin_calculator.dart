import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:unicons/unicons.dart';

import '../../../provider/student_provider.dart';
import '../../student.dart';
import '../teacher_screen.dart';

class Coin_calculator extends StatelessWidget {
  const Coin_calculator({super.key});

  @override
  Widget build(BuildContext context) {
    var studentProvider = Provider.of<StudentProvider>(context);

    void add() {
      studentProvider.incrementAllSelected();
    }

    void minus() {
      studentProvider.decrementAllSelected();
    }

    // Adjust icon size based on device type
    double iconSize = isTablet(context)
        ? math.min(MediaQuery.of(context).size.width * 0.35,
            80.0) // Larger size for tablets
        : math.min(MediaQuery.of(context).size.width * 0.2,
            60.0); // Original size for mobile

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            GestureDetector(
              onTap: minus,
              child: Icon(UniconsLine.minus_circle,
                  size: iconSize, color: const Color.fromRGBO(245, 142, 11, 1)),
            ),
            GestureDetector(
              onTap: add,
              child: Icon(UniconsLine.plus_circle,
                  size: iconSize, color: const Color.fromRGBO(245, 142, 11, 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class Mini_Coin_calculator extends StatelessWidget {
  final ValueNotifier<Student> studentNotifier;

  const Mini_Coin_calculator({super.key, required this.studentNotifier});

  @override
  Widget build(BuildContext context) {
    var studentProvider = Provider.of<StudentProvider>(context);

    // Adjust sizes based on device type
    double iconSize = isTablet(context)
        ? 40.0 // Larger icon size for tablets
        : math.max(MediaQuery.of(context).size.width * 0.06,
            30.0); // Base icon size for mobile
    double fontSize = isTablet(context)
        ? 24.0 // Larger font size for tablets
        : math.max(MediaQuery.of(context).size.width * 0.05,
            16.0); // Base font size for mobile

    void add() {
      studentProvider.incrementCoins(studentNotifier);
    }

    void minus() {
      studentProvider.decrementCoins(studentNotifier);
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            GestureDetector(
              onTap: add,
              child: Icon(UniconsLine.plus_circle,
                  size: iconSize, color: Colors.white),
            ),
            ValueListenableBuilder<Student>(
                valueListenable: studentNotifier,
                builder: (context, student, _) {
                  return Text(
                    '${student.localCoins.value}',
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  );
                }),
            GestureDetector(
              onTap: minus,
              child: Icon(UniconsLine.minus_circle,
                  size: iconSize, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
