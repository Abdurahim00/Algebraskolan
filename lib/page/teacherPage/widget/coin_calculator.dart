import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:unicons/unicons.dart';

import '../../../provider/student_provider.dart';
import '../../student.dart';

class Coin_calculator extends StatelessWidget {
  const Coin_calculator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var studentProvider = Provider.of<StudentProvider>(context);

    void add() {
      studentProvider.incrementAllSelected();
    }

    void minus() {
      studentProvider.decrementAllSelected();
    }

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FittedBox(
              child: GestureDetector(
                  onTap: minus,
                  child: Icon(
                    UniconsLine.minus_circle,
                    size: MediaQuery.of(context).size.width * 0.15,
                    color: Color.fromRGBO(245, 142, 11, 1),
                  )),
            ),
            FittedBox(
              child: GestureDetector(
                onTap: add,
                child: Icon(
                  UniconsLine.plus_circle,
                  size: MediaQuery.of(context).size.width * 0.15,
                  color: Color.fromRGBO(245, 142, 11, 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Mini_Coin_calculator extends StatelessWidget {
  final ValueNotifier<Student> studentNotifier;

  const Mini_Coin_calculator({Key? key, required this.studentNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var studentProvider = Provider.of<StudentProvider>(context);

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
              child: Transform(
                transform: Matrix4.rotationX(math.pi),
                alignment: Alignment.center,
                child: const Icon(
                  UniconsLine.plus_circle,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
            ValueListenableBuilder<Student>(
                valueListenable: studentNotifier,
                builder: (context, student, _) {
                  return FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                        '${student.localCoins.value}', // Here, change coins to localCoins.value
                        style: const TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  );
                }),
            GestureDetector(
              onTap: minus,
              child: const Icon(
                UniconsLine.minus_circle,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
