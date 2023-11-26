import 'package:flutter/material.dart';
import '../provider/connectivity_provider.dart'; // Import your connectivity provider

class NetworkAlertPopup {
  static void show(BuildContext context,
      ConnectivityController connectivityController, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Set to true if you want to allow dismissing by tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: const Icon(Icons.warning, color: Colors.white),
          content: const Text(
            'No Internet Connection',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }
}
