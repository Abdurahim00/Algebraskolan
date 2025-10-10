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

    print('HomePage: Starting getUserDataStream');

    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    // Remote Config already fetched in main.dart, just read the value
    bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');
    print('HomePage: allowAllEmails = $allowAllEmails');

    await for (var user in authRepository.authStateChanges) {
      print('HomePage: Auth state changed - user: ${user?.uid}');
      if (user == null) {
        print('HomePage: No user logged in');
        yield null;
      } else {
        final email = user.email;
        print('HomePage: User email: $email');

        if (!allowAllEmails &&
            !(email?.endsWith('@algebraskolan.se') ?? false) &&
            !(email?.endsWith('@algebrautbildning.se') ?? false)) {
          print('HomePage: Unauthorized email domain');
          await showUnauthorizedDomainDialog(context);
          await signOutUser(context, user);
        } else {
          print('HomePage: Fetching user data for uid: ${user.uid}');
          var userData = await userRepository.getUserData(user.uid);
          if (userData != null) {
            print('HomePage: User data found - role: ${userData['role']}');
            yield UserData(user, userData);
          } else {
            // User exists in Auth but not in Firestore - likely a new user
            // Redirect to login page to complete registration
            print('HomePage: User ${user.uid} exists in Auth but not in Firestore');
            await signOutUser(context, user);
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
          } else if (snapshot.connectionState == ConnectionState.active && userData == null) {
            // No user logged in, show login page
            return const LoginPage();
          }
        }

        return Scaffold(
          backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
          body: Center(
            child: _SpinningLogo(),
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

class _SpinningLogo extends StatefulWidget {
  @override
  State<_SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<_SpinningLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Image.asset(
          "assets/images/favicon.png",
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}