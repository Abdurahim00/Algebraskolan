import 'package:flutter/material.dart';
import 'package:algebra/provider/connectivity_provider.dart'; // Ensure you have the correct import for ConnectivityController
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:algebra/backend/control_page.dart'; // Ensure you have the correct import for HomePage or the desired next screen

import 'network_alert.dart'; // Import NetworkAlertPopup

class SplashScreen extends StatelessWidget {
  final ConnectivityController connectivityController;

  const SplashScreen({Key? key, required this.connectivityController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: connectivityController.checkConnectivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data!) {
          return AnimatedSplashScreen(
            splashIconSize: 200,
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            splash: Image.asset("assets/images/favicon.png",
                width: 100, // Adjust width and height as needed
                height: 100,
                fit: BoxFit.contain),
            nextScreen: HomePage(), // Replace with your desired screen
          );
        } else {
          // Trigger the NetworkAlertPopup instead of returning a widget
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NetworkAlertPopup.show(
              context,
              connectivityController,
              () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => SplashScreen(
                      connectivityController: connectivityController),
                ));
              },
            );
          });
          return Container(); // Return an empty container
        }
      },
    );
  }
}
