import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Make sure to import the Lottie package

class CoinWidget extends StatefulWidget {
  final String uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CoinWidget({Key? key, required this.uid}) : super(key: key);

  @override
  _CoinWidgetState createState() => _CoinWidgetState();
}

class _CoinWidgetState extends State<CoinWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _fetchCoins();
  }

  Future<void> _fetchCoins() async {
    DocumentSnapshot snapshot =
        await widget.firestore.collection('users').doc(widget.uid).get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    _coins = data?['coins'] ?? 0;

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animation =
        Tween<double>(begin: 0, end: _coins.toDouble()).animate(_controller!)
          ..addListener(() {
            setState(() {});
          });

    _controller!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final formattedCoins = NumberFormat("####").format(_animation?.value ?? 0);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Lottie animation
          Text(
            ' $formattedCoins',
            style: GoogleFonts.lilitaOne(fontSize: 32),
          ),
          Container(
              width: 200,
              child: Lottie.asset("assets/images/Coin Simple.json")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
