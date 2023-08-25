import 'package:auto_size_text/auto_size_text.dart';
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
      duration: Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.08;
    final width = MediaQuery.of(context).size.width * 0.5;
    return StreamBuilder<DocumentSnapshot>(
      stream: coinStream,
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.hasError) {
          content = Text("Error fetching data");
        } else if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic>? data =
              snapshot.data!.data() as Map<String, dynamic>?;
          int newCoinsValue = data?['coins'] ?? 0;
          String? displayName = data?['displayName'];

          if (newCoinsValue != _coins) {
            _coins = newCoinsValue;
            _animation = Tween<double>(
                    begin: _animation?.value ?? 0, end: _coins.toDouble())
                .animate(_controller!)
              ..addListener(() {
                setState(() {});
              });

            _controller!.forward(from: 0);
            _lottieController!.forward(from: 0);
          }

          final formattedCoins =
              NumberFormat("####").format(_animation?.value ?? _coins);

          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                ' $formattedCoins Algebronor',
                style: GoogleFonts.lilitaOne(fontSize: 32, color: Colors.black),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (context, constraints) {
                    double topPosition =
                        constraints.maxHeight * 0.18; // 10% from the top
                    double leftPosition = constraints.maxWidth * 0.15;
                    // 10% from the left
                    return Stack(
                      children: [
                        // This is the Lottie animation at the bottom of the stack.
                        Lottie.asset(
                          "assets/images/credit-card.json",
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController!.duration = composition.duration;
                          },
                        ),
                        // Using Positioned to overlay the displayName on the card.
                        displayName != null
                            ? Positioned(
                                top: topPosition,
                                left: leftPosition,
                                child: Center(
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 1.0),
                                    width: width,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.transparent,
                                          width: 2.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: AutoSizeText(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dancingScript(
                                        fontSize: fontSize,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        } else {
          content = Center(
              child: Lottie.asset("assets/images/Circle Loading.json",
                  width: MediaQuery.of(context).size.width *
                      0.2)); // Placeholder while data is loading
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: content,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _lottieController?.dispose();

    super.dispose();
  }
}
