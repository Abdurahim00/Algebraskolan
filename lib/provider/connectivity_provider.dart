import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityController extends ChangeNotifier {
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  Future<void> init() async {
    await checkConnectivity(); // Initial check
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      isInternetConnected(results);
    });
  }

  Future<bool> checkConnectivity() async {
    List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    return isInternetConnected(results);
  }

  bool isInternetConnected(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      isConnected.value = false;
      return false;
    } else {
      isConnected.value = true;
      return true;
    }
  }
}
