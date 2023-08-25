import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Make sure to import this
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
    return Scaffold(
      body: Stack(
        children: [
          // Lottie animation in the background
          Positioned.fill(
            child: Lottie.asset('assets/images/Gradient Circles Warm.json',
                fit: BoxFit.cover),
          ),
          // Your login page content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Välkommen",
                    style: GoogleFonts.lilitaOne(
                        // set the font style using GoogleFonts API
                        fontSize: 36, // set fontSize directly here
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Signa up dig med Algebraskolans mail",
                    style: GoogleFonts.lilitaOne(
                        // set the font style using GoogleFonts API
                        fontSize: 20, // set fontSize directly here
                        color: Colors.white),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50)),
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    final provider = Provider.of<GoogleSignInProvider>(context,
                        listen: false);
                    provider.googleLogin(context);
                  },
                  label: const Text("Sign Up with Google"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
