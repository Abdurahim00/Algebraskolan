import 'package:flutter/material.dart';
import '../provider/connectivity_provider.dart';
import 'network_alert.dart';

class ConnectionAlert extends StatefulWidget {
  const ConnectionAlert({Key? key}) : super(key: key);

  @override
  State<ConnectionAlert> createState() => _ConnectionAlertState();
}

class _ConnectionAlertState extends State<ConnectionAlert> {
  final ConnectivityController connectivityController =
      ConnectivityController();

  @override
  void initState() {
    super.initState();
    connectivityController.init();
  }

  void _handleRetry() {
    // Recheck internet connection
    connectivityController.checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: connectivityController.isConnected,
      builder: (context, isConnected, child) {
        if (!isConnected) {
          // Trigger the NetworkAlertPopup if not connected
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NetworkAlertPopup.show(
              context,
              connectivityController,
              _handleRetry,
            );
          });
        }
        // Return an empty container or the main content of the screen
        return SizedBox();
      },
    );
  }
}
