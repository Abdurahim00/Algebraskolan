import 'package:flutter/material.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:algebra/backend/control_page.dart';
import 'network_alert.dart';

class SplashScreen extends StatelessWidget {
  final ConnectivityController connectivityController;

  const SplashScreen({super.key, required this.connectivityController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: connectivityController.checkConnectivity(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!) {
          return AnimatedSplashScreen(
            duration: 1500,
            splashIconSize: 200,
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
            splash: _AnimatedLogo(),
            nextScreen: HomePage(),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
            body: Center(
              child: _AnimatedLogo(),
            ),
          );
        } else {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
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
                },
                child: const Text('Check Connection'),
              ),
            ),
          );
        }
      },
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Continuous pulse animation
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/favicon.png",
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
