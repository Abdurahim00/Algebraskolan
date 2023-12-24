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

  Stream<UserData?> getUserDataStream() {
    return _authService.authStateChanges.asyncMap((user) async {
      if (user == null) return Future.value(null);

      try {
        var userDocument = await _authService.getUserDocument(user.uid);
        if (userDocument.exists && userDocument.data() != null) {
          return UserData(user, userDocument.data() as Map<String, dynamic>);
        } else {
          debugPrint('Creating initial user data for new user');
          // Initialize new user data here or simply return a UserData with defaults
          return UserData(user, {
            'role': 'student',
            'classNumber': 0,
            'coins': 0,
            'hasAnsweredQuestionCorrectly': false,
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        throw e;
      }
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
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.data?.user != null) {
            var userData = snapshot.data!.userData;
            if (userData != null) {
              // User is logged in and userData is available
              return _buildUserScreen(userData);
            } else {
              // User is logged in but userData is not yet available
              // Redirect to a default or temporary screen
              return _buildTemporaryScreen();
            }
          }

          return const LoginPage();
        },
      ),
    );
  }

  Widget _buildUserScreen(Map<String, dynamic> userData) {
    if (userData['role'] == 'teacher') {
      return const TeacherScreen();
    } else {
      int classNumber = userData['classNumber'];
      if (!userData['hasAnsweredQuestionCorrectly']) {
        return QuestionsScreen(
            key: _questionsScreenKey, classNumber: classNumber);
      } else {
        return const StudentScreen();
      }
    }
  }

  Widget _buildTemporaryScreen() {
    // This screen is shown while user data is being fetched
    return Center(
      child: CircularProgressIndicator(),
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
