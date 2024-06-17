import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';


class CoinWidget extends StatefulWidget {
  final String uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CoinWidget({super.key, required this.uid});

  @override
  _CoinWidgetState createState() => _CoinWidgetState();
}

class _CoinWidgetState extends State<CoinWidget> with TickerProviderStateMixin {
  AnimationController? _controller;
  AnimationController? _lottieController;
  String? _lottieAnimation;

  Animation<double>? _animation;

  int _coins = 0;
  String? _displayName;

  Stream<DocumentSnapshot>? get coinStream {
    if (widget.uid.isNotEmpty) {
      return widget.firestore.collection('users').doc(widget.uid).snapshots();
    } else {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _lottieController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  void _handleAnimation(int newCoinsValue) {
    if (newCoinsValue != _coins) {
      _coins = newCoinsValue;
      _animation =
          Tween<double>(begin: _animation?.value ?? 0, end: _coins.toDouble())
              .animate(_controller!)
            ..addListener(() {
              setState(() {});
            });

      _controller!.forward(from: 0);
      _lottieController!.forward(from: 0);
    }
  }

  Future<void> _loadAndModifyLottie(String displayName) async {
    if (_displayName == displayName && _lottieAnimation != null) {
      return; // Avoid reloading if the name hasn't changed and animation is already loaded
    }

    try {
      String lottieJson = await DefaultAssetBundle.of(context)
          .loadString('assets/images/Credit_card_final.json');
      Map<String, dynamic> lottieMap = json.decode(lottieJson);

      _replaceTextInLottie(
          lottieMap,
          "ABCDEFGHIJKLMNOPQRSTUVWXYZÅ Ä-Öabcdefghijklmnopqrstuvwxyzåäö",
          displayName);

      setState(() {
        _lottieAnimation = json.encode(lottieMap);
        _displayName = displayName;
      });
    } catch (e) {
      print("Error loading or modifying Lottie JSON: $e");
    }
  }

  void _replaceTextInLottie(
      Map<String, dynamic> json, String placeholder, String newText) {
    bool placeholderFound = false;
    if (json.containsKey('layers')) {
      for (var layer in json['layers']) {
        if (layer['ty'] == 5 &&
            layer['t'] != null &&
            layer['t']['d'] != null &&
            layer['t']['d']['k'] != null) {
          for (var k in layer['t']['d']['k']) {
            if (k['s'] != null && k['s']['t'] != null) {
              if (k['s']['t'].contains(placeholder)) {
                k['s']['t'] = k['s']['t'].replaceAll(placeholder, newText);
                placeholderFound = true;
              }
            }
          }
        }
      }
    }
    if (!placeholderFound) {
      print("Placeholder not found in Lottie JSON");
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = isTablet(context) ? 48.0 : 30.0;
    final width =
        MediaQuery.of(context).size.width * 0.8; // Adjust width if needed
    final scaleFactor = 1.4; // Adjust this value to scale the Lottie animation

    return StreamBuilder<DocumentSnapshot>(
      stream: coinStream,
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.hasError) {
          content = const Text("Error fetching data");
        } else if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic>? data =
              snapshot.data!.data() as Map<String, dynamic>?;
          int newCoinsValue = data?['coins'] ?? 0;
          String? displayName = data?['displayName'];

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAnimation(newCoinsValue);
            if (displayName != null) {
              _loadAndModifyLottie(displayName);
            }
          });

          final formattedCoins =
              NumberFormat("####").format(_animation?.value ?? _coins);

          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                ' $formattedCoins Algebronor',
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: isTablet(context) ? 42 : 32,
                  color: Colors.black,
                ),
              ),
              Transform.scale(
                scale: scaleFactor, // Apply the scale factor here
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.8, // Adjust width if needed
                  child: AspectRatio(
                    aspectRatio: 1, // Keep the aspect ratio
                    child: _lottieAnimation == null
                        ? Container()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  LottieBuilder.memory(
                                    Uint8List.fromList(
                                        utf8.encode(_lottieAnimation!)),
                                    controller: _lottieController,
                                    onLoaded: (composition) {
                                      _lottieController!.duration =
                                          composition.duration;
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        } else {
          content = Center(
            child: Lottie.asset(
              "assets/images/Circle Loading.json",
              width: MediaQuery.of(context).size.width * 0.2,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.center,
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

bool isTablet(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final diagonal = sqrt(size.width * size.width + size.height * size.height);
  return diagonal > 1100.0;
}
