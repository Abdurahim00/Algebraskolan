import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:algebra/page/splash_screen.dart';
import 'package:algebra/page/network_alert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final googleSignInProvider = GoogleSignInProvider.instance;
  await googleSignInProvider.initializeUser();
  final connectivityController = ConnectivityController();
  await connectivityController.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('sv_SE', null); // Initialize date format

  runApp(MyApp(connectivityController: connectivityController));
}

class MyApp extends StatelessWidget {
  final ConnectivityController connectivityController;

  const MyApp({super.key, required this.connectivityController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GoogleSignInProvider.instance),
        ChangeNotifierProvider(create: (context) => StudentProvider()),
        ChangeNotifierProvider(create: (context) => QuestionProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final googleSignInProvider =
                Provider.of<GoogleSignInProvider>(context, listen: false);
            return TransactionProvider(
              uid: googleSignInProvider.uid,
              googleSignInProvider: googleSignInProvider,
            );
          },
        ),
        ChangeNotifierProvider.value(
            value: connectivityController), // Added this line
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
