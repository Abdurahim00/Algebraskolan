import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/apple_sign_in_provider.dart';
import '../provider/google_sign_In.dart';
import '../other/network_alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Correct this part
    Future.delayed(Duration.zero, () {
      _checkFirstLaunch(); // Call this method to check first launch and show dialog conditionally
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await _showFirstLaunchDialog();
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  Future<void> _showFirstLaunchDialog() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Algebraskolan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This school uses Google Workspace for education.'),
                Text('Please sign in with your school email'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Understand'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
              'assets/images/Gradient Circles Warm.json', // Ensure your asset path is correct
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Spacer(),
                Text(
                  'Welcome to Algebraskolan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  "Please sign in with your school email.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(
                        parent: _animationController, curve: Curves.easeInOut),
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      if (await connectivityController.isConnected.value) {
                        final GoogleSignInProvider provider =
                            Provider.of<GoogleSignInProvider>(context,
                                listen: false);
                        provider.googleLogin(context, connectivityController);
                      } else {
                        NetworkAlertPopup.show(
                          context,
                          connectivityController,
                          () async {
                            if (await connectivityController
                                .checkConnectivity()) {
                              final GoogleSignInProvider provider =
                                  Provider.of<GoogleSignInProvider>(context,
                                      listen: false);
                              provider.googleLogin(
                                  context, connectivityController);
                            }
                          },
                        );
                      }
                    },
                    icon: Icon(Icons.login),
                    label: Text("Sign in with Google"),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
