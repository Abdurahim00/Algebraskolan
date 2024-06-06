import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/google_sign_In.dart'; // Make sure this import is correct
import '../other/network_alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final emailController = TextEditingController(); // Controller for email input

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFirstLaunchDialog();
        prefs.setBool('isFirstLaunch', false);
      });
    }
  }

  Future<void> _showFirstLaunchDialog() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Algebraskolan'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This school uses Google Workspace for education.'),
                Text('Please sign in with your school email'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Understand'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void handleLoginPress() async {
    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      final provider =
          Provider.of<GoogleSignInProvider>(context, listen: false);
      final connectivityController =
          Provider.of<ConnectivityController>(context, listen: false);
      if (await provider.checkIfUserExists(email)) {
        provider.googleLogin(context, connectivityController);
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("User Not Found"),
                content: const Text(
                    "No account associated with this email. Please check your email address or register."),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"))
                ],
              );
            });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email.")));
    }
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
          Center(
            // Center the main column in the stack
            child: SingleChildScrollView(
              // Makes the content scrollable if it doesn't fit
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Welcome to the Algebra School',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Text(
                    //   "Ange algebraskolans mail för att logga in.",
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(fontSize: 20, color: Colors.white),
                    // ),
                    const SizedBox(height: 48),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //         color: Colors.grey[200],
                    //         border: Border.all(color: Colors.white),
                    //         borderRadius: BorderRadius.circular(12)),
                    //     child: Padding(
                    //       padding: const EdgeInsets.only(left: 20.0),
                    //       child: TextField(
                    //         controller: emailController,
                    //         decoration: const InputDecoration(
                    //           border: InputBorder.none,
                    //           hintText: 'Email',
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 20),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    //   child: GestureDetector(
                    //     onTap: handleLoginPress,
                    //     child: Container(
                    //       height:
                    //           60, // Adjust height to match your design preference
                    //       decoration: BoxDecoration(
                    //           color: Colors.deepOrange,
                    //           borderRadius: BorderRadius.circular(12)),
                    //       child: Center(
                    //         child: Text(
                    //           'Logga In',
                    //           style: TextStyle(
                    //               color: Colors.white,
                    //               fontWeight: FontWeight.bold,
                    //               fontSize: 18),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 20),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text('Inte medlem?',
                    //         style: TextStyle(fontWeight: FontWeight.bold)),
                    //     Text(
                    //       ' Registrera med Google',
                    //       style: TextStyle(
                    //           color: Colors.deepOrange,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 10),
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
                                child: FloatingActionButton.extended(
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
                                  icon: const Icon(Icons.login),
                                  label: const Text("Register with Google"),
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                              );
                      },
                    ),
                    SizedBox(height: 32),
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
