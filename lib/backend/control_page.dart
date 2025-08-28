import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/pages/login.dart';
import 'package:algebra/pages/studentPage/student_screen.dart';
import 'package:algebra/pages/teacherPage/teacher_screen.dart';
import 'package:algebra/provider/google_sign_in.dart';
import '../core/di/injection_container.dart';
import '../pages/studentPage/question_screen.dart';

class UserData {
  final User? user;
  final Map<String, dynamic>? userData;

  UserData(this.user, this.userData);
}

class HomePage extends StatelessWidget {
  final GlobalKey<QuestionsScreenState> _questionsScreenKey = GlobalKey();

  HomePage({super.key});

  Stream<UserData?> getUserDataStream(BuildContext context) async* {
    final authRepository = InjectionContainer.authRepository;
    final userRepository = InjectionContainer.userRepository;
    
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

    await for (var user in authRepository.authStateChanges) {
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
          var userData = await userRepository.getUserData(user.uid);
          if (userData != null) {
            yield UserData(user, userData);
          } else {
            yield null;
          }
        }
      }
    }
  }

  Future<void> signOutUser(BuildContext context, User user) async {
    final authRepository = InjectionContainer.authRepository;
    await authRepository.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserData?>(
      stream: getUserDataStream(context),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Fel'),
                  content: const Text('Ett fel uppstod. Försök igen senare.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          });
        }

        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          var userData = snapshot.data;

          if (userData != null && userData.user != null) {
            if (userData.userData?['role'] == 'teacher') {
              return TeacherScreen();
            } else if (userData.userData?['role'] == 'student') {
              if (userData.userData?['hasAnsweredQuestionCorrectly'] ==
                  false) {
                final classNumber = userData.userData?['classNumber'] ?? 0;
                return QuestionsScreen(
                  key: _questionsScreenKey,
                  classNumber: classNumber,
                );
              } else {
                return StudentScreen();
              }
            }
          }
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/images/Circle Loading.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Laddar...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showUnauthorizedDomainDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Obehörig domän'),
          content: const Text(
              'Endast användare med @algebraskolan.se eller @algebrautbildning.se e-postadresser kan logga in.'),
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
}