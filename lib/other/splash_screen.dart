import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:algebra/backend/control_page.dart'; // Replace with your desired next screen

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSplashScreen(
          splashIconSize: 200,
          splashTransition: SplashTransition.fadeTransition,
          pageTransitionType: PageTransitionType.fade,
          splash: Image.asset(
            "assets/images/favicon.png",
            width: 100, // Adjust width and height as needed
            height: 100,
            fit: BoxFit.contain,
          ),
          nextScreen: HomePage(), // Replace with your desired screen
        ),
      ),
    );
  }
}
