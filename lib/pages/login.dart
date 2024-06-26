import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:lottie/lottie.dart';

import '../provider/google_sign_In.dart'; // Make sure this import is correct
import '../other/network_alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final emailController = TextEditingController(); // Controller for email input

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

    // Start the fade-in animation when the widget is built
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    emailController.dispose(); // Dispose the controller
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
            alignment: Alignment.topCenter, // Align the logo at the top center
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0), // Add some top padding
              child: Image.asset(
                'assets/images/Algebraskolan4.png',
                height: 80,
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
                    const SizedBox(height: 100), // Add space below the logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Välkommen',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Registrera dig med Algebraskolans mail",
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(height: 48),
                    Consumer<GoogleSignInProvider>(
                      builder: (context, provider, child) {
                        return provider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.orange)
                            : ScaleTransition(
                                scale: Tween(begin: 0.95, end: 1.05).animate(
                                  CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeInOut),
                                ),
                                child: OutlinedButton(
                                  onPressed: () async {
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/google-logo.png',
                                        height: 40.0,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
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
