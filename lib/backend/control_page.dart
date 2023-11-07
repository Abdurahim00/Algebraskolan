import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:algebra/page/login.dart';
import 'package:algebra/page/studentPage/student_screen.dart';
import 'package:algebra/page/teacherPage/teacher_screen.dart';
import 'package:lottie/lottie.dart';
import '../page/studentPage/question_screen.dart';
import 'auth_service.dart';

// UserManager to cache and provide user data
class UserManager with ChangeNotifier {
  Map<String, dynamic>? _userData;
  final UserAuthService _authService = UserAuthService();

  Map<String, dynamic>? get userData => _userData;

  Future<void> fetchUserData(String uid) async {
    if (_userData == null) {
      DocumentSnapshot userDoc = await _authService.getUserDocument(uid);
      _userData = userDoc.data() as Map<String, dynamic>?;
      notifyListeners();
    }
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Center(
              child: Lottie.asset("assets/images/Circle Loading.json",
                  width: screenWidth * 0.2),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Något gick fel!"));
          } else if (snapshot.data != null) {
            // Use UserManager to fetch and provide user data
            return ChangeNotifierProvider<UserManager>(
              create: (_) => UserManager()..fetchUserData(snapshot.data!.uid),
              child: Consumer<UserManager>(
                builder: (context, userManager, _) {
                  final userData = userManager.userData;
                  if (userData == null) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    return Center(
                      child: Lottie.asset("assets/images/Circle Loading.json",
                          width: screenWidth * 0.2),
                    );
                  } else {
                    print('User Data: $userData'); // print all the user data
                    if (userData['role'] == 'teacher') {
                      return const TeacherScreen();
                    } else {
                      int classNumber = userData['classNumber'];
                      if (userData['hasAnsweredQuestionCorrectly'] == false) {
                        // redirecting to questionscreen
                        return QuestionsScreen(classNumber: classNumber);
                      } else {
                        // go to studentscreen
                        return StudentScreen();
                      }
                    }
                  }
                },
              ),
            );
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
