import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/pages/admin_menu.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../provider/google_sign_In.dart';
import '../provider/apple_sign_in_provider.dart';
import '../other/network_alert.dart';
import '../widgets/skeleton_loading.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityController =
        Provider.of<ConnectivityController>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset(
              'assets/images/Gradient Circles Warm.json',
              controller: _animationController,
              onLoaded: (composition) {
                _animationController
                  ..duration = composition.duration
                  ..repeat();
              },
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: GestureDetector(
                onLongPress: () {
                  // Hidden admin access
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminMenu(),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/Algebraskolan4.png',
                  height: 80,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 100),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Välkommen',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Registrera dig med Algebraskolans mail',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Consumer<GoogleSignInProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: Tween(begin: 0.95, end: 1.05).animate(
                            CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.easeInOut),
                          ),
                          child: OutlinedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (connectivityController
                                        .isConnected.value) {
                                      provider.googleLogin(
                                          context, connectivityController);
                                    } else {
                                      NetworkAlertPopup.show(
                                          context, connectivityController,
                                          () async {
                                        if (await connectivityController
                                            .checkConnectivity()) {
                                          provider.googleLogin(
                                              context, connectivityController);
                                        }
                                      });
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (provider.isLoading)
                                  const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Color.fromRGBO(245, 142, 11, 1)),
                                      ),
                                    ),
                                  )
                                else
                                  Image.asset(
                                    'assets/images/google-logo.png',
                                    height: 40.0,
                                  ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Anslut',
                                  style: TextStyle(
                                    fontFamily: 'LilitaOne',
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Only show Apple Sign In button on iOS
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 32),
                      Consumer<AppleSignInProvider>(
                        builder: (context, provider, child) {
                          return ScaleTransition(
                            scale: Tween(begin: 0.95, end: 1.05).animate(
                              CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeInOut),
                            ),
                            child: OutlinedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      if (connectivityController
                                          .isConnected.value) {
                                        provider.appleLogin(
                                            context, connectivityController);
                                      } else {
                                        NetworkAlertPopup.show(
                                            context, connectivityController,
                                            () async {
                                          if (await connectivityController
                                              .checkConnectivity()) {
                                            provider.appleLogin(
                                                context, connectivityController);
                                          }
                                        });
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (provider.isLoading)
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      height: 40.0,
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.apple,
                                          color: Colors.white,
                                          size: 40.0,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Anslut',
                                    style: TextStyle(
                                      fontFamily: 'LilitaOne',
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
