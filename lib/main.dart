import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:algebra/other/splash_screen.dart';
import 'package:algebra/other/network_alert.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// Dependency Injection
import 'core/di/service_locator.dart';
import 'core/config/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  
  // Initialize app configuration
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  initializeAppConfig(environment);
  
  // Initialize dependency injection
  await setupServiceLocator();
  
  await setupRemoteConfig(); // Fetch and activate remote config with quick settings

  // Get instances from service locator
  final googleSignInProvider = sl<GoogleSignInProvider>();
  await googleSignInProvider.initializeUser();

  final connectivityController = sl<ConnectivityController>();
  await connectivityController.init();

  await initializeDateFormatting('sv_SE', null); // Initialize date format

  runApp(MyApp(
    googleSignInProvider: googleSignInProvider,
    connectivityController: connectivityController,
  ));
}

Future<void> setupRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  // Set the minimum fetch interval to 0 during development for faster results.
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(
        seconds: 0), // Set to 0 for fast fetch during development
  ));

  await remoteConfig.setDefaults({'allow_all_emails_for_review': false});

  try {
    await remoteConfig.fetchAndActivate();
    print("Remote Config fetched and activated");
  } catch (e) {
    print("Remote Config fetch failed: $e");
  }
}

class MyApp extends StatelessWidget {
  final GoogleSignInProvider googleSignInProvider;
  final ConnectivityController connectivityController;

  const MyApp({
    super.key,
    required this.googleSignInProvider,
    required this.connectivityController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
        ChangeNotifierProvider.value(value: connectivityController),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
