import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:algebra/page/login.dart';
import 'package:algebra/page/studentPage/student_screen.dart';
import 'package:algebra/page/teacherPage/teacher_screen.dart';
import 'package:lottie/lottie.dart';
import '../page/studentPage/question_screen.dart';
import 'auth_service.dart';

class HomePage extends StatelessWidget {
  final UserAuthService _authService = UserAuthService();

  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.orange,
            ));
          } else if (snapshot.hasError) {
            return const Center(child: Text("Something Went Wrong!"));
          } else if (snapshot.data != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: _authService.getUserDocument(snapshot.data!.uid),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot2) {
                if (snapshot2.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: Lottie.asset(
                    "assets/images/Pendulum.json",
                  ));
                } else if (snapshot2.hasError) {
                  return const Center(child: Text("Something Went Wrong!"));
                } else if (snapshot2.hasData) {
                  Map<String, dynamic> data =
                      snapshot2.data!.data() as Map<String, dynamic>;
                  print('User Data: $data'); // print all the user data
                  if (data['role'] == 'teacher') {
                    return const TeacherScreen();
                  } else {
                    int classNumber = data['classNumber'];
                    final questionAnsweredAt =
                        data['questionAnsweredAt']?.toDate();
                    if (questionAnsweredAt != null) {
                      final now = DateTime.now();
                      final difference =
                          now.difference(questionAnsweredAt).inSeconds;
                      print(
                          'Time difference: $difference'); // print time difference
                      if (difference > 30 * 60 ||
                          data['hasAnsweredQuestionCorrectly'] == false) {
                        print(
                            'Redirecting to QuestionsScreen'); // print redirection action
                        return QuestionsScreen(classNumber: classNumber);
                      } else {
                        print(
                            'Redirecting to StudentScreen'); // print redirection action
                        return StudentScreen();
                      }
                    } else {
                      print(
                          'Redirecting to QuestionsScreen due to null timestamp'); // print redirection action
                      return QuestionsScreen(classNumber: classNumber);
                    }
                  }
                } else {
                  return const LoginPage();
                }
              },
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
