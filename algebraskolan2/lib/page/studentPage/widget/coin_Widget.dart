import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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

  Stream<DocumentSnapshot> get coinStream =>
      widget.firestore.collection('users').doc(widget.uid).snapshots();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: coinStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error fetching data");
        } else if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic>? data =
              snapshot.data!.data() as Map<String, dynamic>?;
          int newCoinsValue = data?['coins'] ?? 0;

          if (newCoinsValue != _coins) {
            _coins = newCoinsValue;
            _animation = Tween<double>(
                    begin: _animation?.value ?? 0, end: _coins.toDouble())
                .animate(_controller!)
              ..addListener(() {
                setState(() {});
              });

            _controller!.forward(from: 0);
          }
        }

        final formattedCoins =
            NumberFormat("####").format(_animation?.value ?? _coins);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
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
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
