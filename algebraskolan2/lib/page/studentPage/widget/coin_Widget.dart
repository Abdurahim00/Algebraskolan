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

class _CoinWidgetState extends State<CoinWidget> with TickerProviderStateMixin {
  AnimationController? _controller;
  AnimationController? _lottieController;

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

    _lottieController = AnimationController(
      duration:
          Duration(seconds: 2), // or your desired duration for Lottie animation
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
            _lottieController!.forward(from: 0); // Start the Lottie animation
          }
        }

        final formattedCoins =
            NumberFormat("####").format(_animation?.value ?? _coins);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment
                  .start, // This will align items to the top of the column
              children: [
                Text(
                  ' $formattedCoins' " Algebronor",
                  style: GoogleFonts.lilitaOne(fontSize: 32),
                ),
                Container(
                  child: Lottie.asset(
                    "assets/images/Coin Simple.json",
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController!.duration = composition.duration;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    //_lottieController?.dispose();

    super.dispose();
  }
}
