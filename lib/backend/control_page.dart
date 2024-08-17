import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/pages/login.dart';
import 'package:algebra/pages/studentPage/student_screen.dart';
import 'package:algebra/pages/teacherPage/teacher_screen.dart';
import 'package:algebra/provider/google_sign_In.dart';

import '../pages/studentPage/question_screen.dart';
import 'auth_service.dart';

class UserData {
  final User? user;
  final Map<String, dynamic>? userData;

  UserData(this.user, this.userData);
}

class HomePage extends StatelessWidget {
  final UserAuthService _authService = UserAuthService();
  final GlobalKey<QuestionsScreenState> _questionsScreenKey = GlobalKey();
  final googleSignInProvider = GoogleSignInProvider.instance;

  HomePage({super.key});

  Stream<UserData?> getUserDataStream(BuildContext context) async* {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

    await for (var user in _authService.authStateChanges) {
      if (user == null) {
        yield null;
      } else {
        final email = user.email;

        if (!allowAllEmails &&
            !(email?.endsWith('@algebraskolan.se') ?? false) &&
            !(email?.endsWith('@algebrautbildning.se') ?? false)) {
          await showUnauthorizedDomainDialog(context);
          await signOutUser(context, user);
        } else {
          var userDocument = await _authService.getUserDocument(user.uid);
          if (userDocument.exists && userDocument.data() != null) {
            yield UserData(user, userDocument.data() as Map<String, dynamic>);
          } else {
            yield null;
          }
        }
      }
    }
  }

  Future<void> signOutUser(BuildContext context, User user) async {
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      await GoogleSignInProvider.instance.googleLogout();
      await GoogleSignInProvider.instance.googleDisconnect();
    }
  }

  Future<void> showUnauthorizedDomainDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Obehörig åtkomst'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bara Algebraskolan mail är tillåtet'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserData?>(
        stream: getUserDataStream(context),
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
              return _buildUserScreen(userData);
            } else {
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
    } else if (userData['role'] == 'student') {
      int classNumber = userData['classNumber'];
      if (!userData['hasAnsweredQuestionCorrectly']) {
        return QuestionsScreen(
            key: _questionsScreenKey, classNumber: classNumber);
      } else {
        return const StudentScreen();
      }
    } else {
      return const LoginPage(); // Or another default page
    }
  }

  Widget _buildTemporaryScreen() {
    return const Center(
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
