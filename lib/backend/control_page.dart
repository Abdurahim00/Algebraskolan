import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/page/login.dart';
import 'package:algebra/page/studentPage/student_screen.dart';
import 'package:algebra/page/teacherPage/teacher_screen.dart';
import '../page/studentPage/question_screen.dart';
import 'auth_service.dart';

class HomePage extends StatelessWidget {
  final UserAuthService _authService = UserAuthService();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // Determine if the app is in a loading state
          bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          return WillPopScope(
            onWillPop: () async => !isLoading,
            child: isLoading
                ? _buildLoadingScreen(context)
                : _buildContentBasedOnSnapshot(context, snapshot),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Lottie.asset("assets/images/Circle Loading.json",
          width: screenWidth * 0.2),
    );
  }

  Widget _buildContentBasedOnSnapshot(
      BuildContext context, AsyncSnapshot<User?> snapshot) {
    if (snapshot.hasError) {
      return const Center(child: Text("Något gick fel!"));
    } else if (snapshot.data != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: _authService.getUserDocument(snapshot.data!.uid),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot2) {
          if (snapshot2.connectionState == ConnectionState.waiting) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Center(
                child: Lottie.asset("assets/images/Circle Loading.json",
                    width: screenWidth * 0.2));
          } else if (snapshot2.hasError) {
            return const Center(child: Text("Något gick fel!"));
          } else if (snapshot2.hasData) {
            Map<String, dynamic> data =
                snapshot2.data!.data() as Map<String, dynamic>;
            if (data['role'] == 'teacher') {
              return const TeacherScreen();
            } else {
              int classNumber = data['classNumber'];
              if (data['hasAnsweredQuestionCorrectly'] == false) {
                return QuestionsScreen(classNumber: classNumber);
              } else {
                return const StudentScreen();
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
  }
}
