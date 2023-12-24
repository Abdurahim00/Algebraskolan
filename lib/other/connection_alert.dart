import 'package:flutter/material.dart';
import '../provider/connectivity_provider.dart';
import 'network_alert.dart';

class ConnectionAlert extends StatefulWidget {
  const ConnectionAlert({super.key});

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
    connectivityController.isConnected.addListener(_connectivityChanged);
  }

  void _connectivityChanged() {
    if (!connectivityController.isConnected.value) {
      if (mounted) {
        showNetworkAlert();
      }
    } else {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      }
    }
  }

  void showNetworkAlert() {
    NetworkAlertPopup.show(
      context,
      connectivityController,
      _handleRetry,
    );
  }

  Future<bool> _handleRetry() async {
    return await connectivityController.checkConnectivity();
  }

  @override
  void dispose() {
    connectivityController.isConnected.removeListener(_connectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Or your main content
  }
}
