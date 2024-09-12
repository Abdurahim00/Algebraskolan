import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // For SystemChrome

import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/other/splash_screen.dart';
import 'add_math_questions.dart'; 
import 'package:algebra/backend/control_page.dart'; // Correct import for HomePage

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAkjr0gCk-FRGj5bwSVoju4iXHfg6OqgyQ",
  authDomain: "algebra-82c5d.firebaseapp.com",
  projectId: "algebra-82c5d",
  storageBucket: "algebra-82c5d.appspot.com",
  messagingSenderId: "195764286049",
  appId: "1:195764286049:web:9f5b88875060f1450d3020",
  databaseURL:
      "https://algebra-82c5d-default-rtdb.europe-west1.firebasedatabase.app",
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(options: firebaseConfig);
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final googleSignInProvider = GoogleSignInProvider.instance;

  try {
    await googleSignInProvider.initializeUser();
  } catch (e) {
    print("Google Sign-In initialization error: $e");
  }

  await initializeDateFormatting('sv_SE', null);

  runApp(MyApp(
    googleSignInProvider: googleSignInProvider,
  ));
}

class MyApp extends StatelessWidget {
  final GoogleSignInProvider googleSignInProvider;

  const MyApp({
    super.key,
    required this.googleSignInProvider,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double iphone15ProMaxWidth = 430.0;
        const double iphone15ProMaxHeight = 932.0;

        double horizontalPadding =
            (constraints.maxWidth - iphone15ProMaxWidth) / 2;
        horizontalPadding = horizontalPadding < 0 ? 0 : horizontalPadding;

        return Container(
          color: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: iphone15ProMaxWidth / iphone15ProMaxHeight,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(iphone15ProMaxWidth, iphone15ProMaxHeight),
                devicePixelRatio: 3.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: googleSignInProvider),
                    ChangeNotifierProvider(create: (context) => StudentProvider()),
                    ChangeNotifierProvider(create: (context) => QuestionProvider()),
                    ChangeNotifierProvider(
                      create: (context) {
                        return TransactionProvider(
                          uid: googleSignInProvider.uid,
                          googleSignInProvider: googleSignInProvider,
                        );
                      },
                    ),
                  ],
                  child: Consumer<GoogleSignInProvider>(
                    builder: (context, provider, child) {
                      return MaterialApp(
                        navigatorKey: navigatorKey,
                        title: 'Algebra App',
                        debugShowCheckedModeBanner: false,
                        home: FutureBuilder<bool>(
                          future: provider.isUserSignedIn(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasData && snapshot.data == true) {
                              return HomePage(); // Ensure HomePage is properly defined and imported
                            } else {
                              return SplashScreen(); // Ensure SplashScreen is properly defined and imported
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
