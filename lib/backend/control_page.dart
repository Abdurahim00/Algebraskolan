import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/page/login.dart';
import 'package:algebra/page/studentPage/student_screen.dart';
import 'package:algebra/page/teacherPage/teacher_screen.dart';
import '../page/studentPage/question_screen.dart';
import 'auth_service.dart';

// Create a custom class to hold both user and user data
class UserData {
  final User? user;
  final Map<String, dynamic>? userData;

  UserData(this.user, this.userData);
}

class HomePage extends StatelessWidget {
  final UserAuthService _authService = UserAuthService();
  final GlobalKey<QuestionsScreenState> _questionsScreenKey = GlobalKey();

  HomePage({super.key});

  // Method to create a combined stream of user and user data
  Stream<UserData?> getUserDataStream() {
    return _authService.authStateChanges.asyncMap((user) async {
      if (user != null) {
        var userDocument = await _authService.getUserDocument(user.uid);
        var userData = userDocument.data() as Map<String, dynamic>;
        return UserData(user, userData);
      }
      return Future.value(null); // Corrected return for null case
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserData?>(
        stream: getUserDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen(context);
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Något gick fel!"));
          }

          if (snapshot.hasData && snapshot.data != null) {
            var data = snapshot.data!.userData;
            if (data!['role'] == 'teacher') {
              return const TeacherScreen();
            } else {
              int classNumber = data['classNumber'];
              if (data['hasAnsweredQuestionCorrectly'] == false) {
                return QuestionsScreen(
                    key: _questionsScreenKey, classNumber: classNumber);
              } else {
                return const StudentScreen();
              }
            }
          } else {
            return const LoginPage();
          }
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
}
