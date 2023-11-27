import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';

class ConnectivityController extends ChangeNotifier {
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  Future<void> init() async {
    await checkConnectivity(); // Initial check
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      isInternetConnected(result);
    });
  }

  Future<bool> checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    return isInternetConnected(result);
  }

  bool isInternetConnected(ConnectivityResult? result) {
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
      return false;
    } else {
      isConnected.value = true;
      return true;
    }
  }
}
