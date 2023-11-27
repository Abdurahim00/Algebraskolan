import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

import '../provider/google_sign_In.dart';
import 'network_alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final connectivityController =
        Provider.of<ConnectivityController>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset('assets/images/Gradient Circles Warm.json',
                fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Välkommen',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Signa up dig med Algebraskolans mail",
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                    minimumSize: MaterialStateProperty.all<Size>(
                        Size(double.infinity, 50)),
                    overlayColor: MaterialStateProperty.all<Color>(
                        Colors.orange.withOpacity(0.2)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.google,
                      color: Colors.orange),
                  onPressed: () async {
                    if (await connectivityController.isConnected.value) {
                      final provider = Provider.of<GoogleSignInProvider>(
                          context,
                          listen: false);
                      provider.googleLogin(context, connectivityController);
                    } else {
                      NetworkAlertPopup.show(context, connectivityController,
                          () async {
                        if (await connectivityController.checkConnectivity()) {
                          final provider = Provider.of<GoogleSignInProvider>(
                              context,
                              listen: false);
                          provider.googleLogin(context, connectivityController);
                        }
                      });
                    }
                  },
                  label: const Text("Sign Up with Google"),
                ),
                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
