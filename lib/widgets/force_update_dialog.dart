import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../utils/version_checker.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String requiredVersion;

  const ForceUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.requiredVersion,
  });

  Future<void> _openStore() async {
    final String storeUrl = VersionChecker.getStoreUrl();
    final Uri url = Uri.parse(storeUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('ForceUpdateDialog: Could not launch $storeUrl');
      }
    } catch (e) {
      print('ForceUpdateDialog: Error launching store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing with back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(245, 142, 11, 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update,
                  size: 64,
                  color: Color.fromRGBO(245, 142, 11, 1),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Uppdatering krävs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LilitaOne',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'En ny version av Algebraskolan är tillgänglig. Uppdatera till version $requiredVersion för att fortsätta.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Version info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuvarande version:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Krävd version:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          requiredVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(245, 142, 11, 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Platform.isIOS
                            ? Icons.apple
                            : Icons.android,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Platform.isIOS
                            ? 'Uppdatera via App Store'
                            : 'Uppdatera via Play Store',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LilitaOne',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

