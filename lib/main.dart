import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/apple_sign_in_provider.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:algebra/provider/fritids_provider.dart';
import 'package:algebra/provider/fritids_history_provider.dart';
import 'package:algebra/provider/fritids_attendance_provider.dart';
import 'package:algebra/other/splash_screen.dart';
import 'package:algebra/other/network_alert.dart';
import 'package:algebra/pages/fritids/fritids_screen.dart';
import 'package:algebra/pages/fritids/fritids_history_screen.dart';
import 'package:algebra/pages/admin/assign_fritids_screen.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:algebra/utils/version_checker.dart';
import 'package:algebra/widgets/force_update_dialog.dart';

// Dependency Injection
import 'core/di/service_locator.dart';
import 'core/config/app_config.dart';
import 'config/firebase_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app configuration first
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  initializeAppConfig(environment);

  // Initialize Firebase - the google-services plugin handles it for each flavor
  await Firebase.initializeApp();

  // Enable offline persistence for better performance
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize dependency injection
  await setupServiceLocator();

  await setupRemoteConfig(); // Fetch and activate remote config with quick settings

  // Get instances from service locator
  final googleSignInProvider = sl<GoogleSignInProvider>();
  await googleSignInProvider.initializeUser();

  final appleSignInProvider = sl<AppleSignInProvider>();
  await appleSignInProvider.initializeUser();

  final connectivityController = sl<ConnectivityController>();
  await connectivityController.init();

  await initializeDateFormatting('sv_SE', null); // Initialize date format

  runApp(MyApp(
    googleSignInProvider: googleSignInProvider,
    appleSignInProvider: appleSignInProvider,
    connectivityController: connectivityController,
  ));
}

Future<void> setupRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  // Set defaults first
  await remoteConfig.setDefaults({'allow_all_emails_for_review': false});

  // Set aggressive timeout for faster startup
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 3), // Reduced from 10 to 3 seconds
    minimumFetchInterval: const Duration(seconds: 0),
  ));

  // Fetch in background, don't block app startup
  remoteConfig.fetchAndActivate().then((_) {
    print("Remote Config fetched and activated");
  }).catchError((e) {
    print("Remote Config fetch failed (using defaults): $e");
  });
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
        ChangeNotifierProvider(create: (context) => FritidsProvider()),
        ChangeNotifierProvider(create: (context) => FritidsHistoryProvider()),
        ChangeNotifierProvider(
            create: (context) => FritidsAttendanceProvider()),
        ChangeNotifierProvider.value(value: connectivityController),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Algebra App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/fritids':
              page = const FritidsScreen();
              break;
            case '/fritids-history':
              page = const FritidsHistoryScreen();
              break;
            case '/assign-fritids':
              page = const AssignFritidsScreen();
              break;
            default:
              return null;
          }
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              var offsetAnimation = animation.drive(tween);

              var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
              var fadeAnimation = animation.drive(fadeTween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
        home: _AppHome(connectivityController: connectivityController),
      ),
    );
  }
}

class _AppHome extends StatefulWidget {
  final ConnectivityController connectivityController;

  const _AppHome({required this.connectivityController});

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool _isCheckingVersion = true;
  bool _needsUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final needsUpdate = await VersionChecker.isUpdateRequired();
      if (mounted) {
        setState(() {
          _needsUpdate = needsUpdate;
          _isCheckingVersion = false;
        });

        // Show force update dialog if needed
        if (_needsUpdate) {
          final currentVersion = await VersionChecker.getCurrentVersion();
          final requiredVersion = await VersionChecker.getMinimumRequiredVersion();

          if (mounted) {
            Future.microtask(() {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ForceUpdateDialog(
                  currentVersion: currentVersion,
                  requiredVersion: requiredVersion,
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      print('Error checking version: $e');
      if (mounted) {
        setState(() {
          _isCheckingVersion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVersion) {
      // Show loading while checking version
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(245, 142, 11, 1),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.connectivityController.isConnected,
      builder: (context, isConnected, child) {
        if (isConnected) {
          return SplashScreen(
            connectivityController: widget.connectivityController,
          );
        } else {
          // Show network alert popup
          Future.microtask(() => NetworkAlertPopup.show(
                context,
                widget.connectivityController,
                () => widget.connectivityController.checkConnectivity(),
              ));
          return Container(); // Return an empty container
        }
      },
    );
  }
}
