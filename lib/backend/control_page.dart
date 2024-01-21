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
    // Initialize and fetch Firebase Remote Config
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

    // Listening to auth state changes
    await for (var user in _authService.authStateChanges) {
      if (user == null) {
        yield null; // Yield null when no user is signed in
      } else {
        final email = user.email;

        // Check if the email domain is allowed based on Remote Config
        if (!allowAllEmails &&
            !(email?.endsWith('@algebraskolan.se') ?? false) &&
            !(email?.endsWith('@algebrautbildning.se') ?? false)) {
          await showUnauthorizedDomainDialog(context);
          await signOutUser(context, user);
          // Do not yield UserData as the user is unauthorized
        } else {
          // Fetch user data from Firestore
          var userDocument = await _authService.getUserDocument(user.uid);
          if (userDocument.exists && userDocument.data() != null) {
            // Yield UserData with user information if available
            yield UserData(user, userDocument.data() as Map<String, dynamic>);
          } else {
            // Yield default UserData if the document doesn't exist
            yield UserData(user, {
              'role': 'student',
              'classNumber': 0,
              'coins': 0,
              'hasAnsweredQuestionCorrectly': false,
            });
          }
        }
      }
    }
  }

  Future<void> signOutUser(BuildContext context, User user) async {
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      await GoogleSignInProvider.instance.googleLogout();
      // Now you can call the new method
      await GoogleSignInProvider.instance.googleDisconnect();
    }
  }

  Future<void> showUnauthorizedDomainDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap the button to close the dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Obehörig Åtkomst'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bara Algebraskolans mail är tillåtet.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
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
