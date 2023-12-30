import 'package:algebra/provider/apple_sign_in_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:algebra/other/splash_screen.dart';
import 'package:algebra/other/network_alert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final googleSignInProvider = GoogleSignInProvider.instance;
  await googleSignInProvider.initializeUser();
  final appleSignInProvider =
      AppleSignInProvider(); // Create an instance of AppleSignInProvider
  await appleSignInProvider.initializeUser(); // Initialize AppleSignInProvider
  final connectivityController = ConnectivityController();
  await connectivityController.init();

  await initializeDateFormatting('sv_SE', null); // Initialize date format

  runApp(MyApp(
    googleSignInProvider: googleSignInProvider,
    appleSignInProvider: appleSignInProvider,
    connectivityController: connectivityController,
  ));
}

class MyApp extends StatelessWidget {
  final GoogleSignInProvider googleSignInProvider;
  final AppleSignInProvider appleSignInProvider;
  final ConnectivityController connectivityController;

  const MyApp({
    super.key,
    required this.googleSignInProvider,
    required this.appleSignInProvider,
    required this.connectivityController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: googleSignInProvider),
        ChangeNotifierProvider.value(value: appleSignInProvider),
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
        ChangeNotifierProvider.value(value: connectivityController),
      ],
      child: MaterialApp(
        title: 'Algebra App',
        debugShowCheckedModeBanner: false,
        home: ValueListenableBuilder<bool>(
          valueListenable: connectivityController.isConnected,
          builder: (context, isConnected, child) {
            if (isConnected) {
              return SplashScreen(
                  connectivityController: connectivityController);
            } else {
              // Show network alert popup
              Future.microtask(() => NetworkAlertPopup.show(
                    context,
                    connectivityController,
                    () => connectivityController.checkConnectivity(),
                  ));
              return Container(); // Return an empty container
            }
          },
        ),
      ),
    );
  }
}
