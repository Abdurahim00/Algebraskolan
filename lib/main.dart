import 'package:algebra/page/network_alert.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/page/splash_screen.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:algebra/page/login.dart'; // Import LoginPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final googleSignInProvider = GoogleSignInProvider.instance;
  await googleSignInProvider.initializeUser();
  final connectivityController = ConnectivityController();
  await connectivityController.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
      (_) => runApp(MyApp(connectivityController: connectivityController)));
}

class MyApp extends StatelessWidget {
  final ConnectivityController connectivityController;

  const MyApp({Key? key, required this.connectivityController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GoogleSignInProvider.instance),
        ChangeNotifierProvider(create: (context) => StudentProvider()),
        ChangeNotifierProvider(create: (context) => QuestionProvider()),
        ChangeNotifierProvider(
          create: (context) => TransactionProvider(
            googleSignInProvider:
                Provider.of<GoogleSignInProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider.value(
            value: connectivityController), // Added this line
      ],
      child: MaterialApp(
        title: 'Algebra App',
        theme: ThemeData(primarySwatch: Colors.blue),
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
