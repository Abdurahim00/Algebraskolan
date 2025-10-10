import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class VersionChecker {
  /// Check if app needs to be updated
  /// Returns true if update is required, false otherwise
  static Future<bool> isUpdateRequired() async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      
      // Get minimum required version from Firebase Remote Config
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      
      // Fetch latest config values
      await remoteConfig.fetchAndActivate();
      
      // Get minimum required version for iOS and Android separately
      final String minVersionIOS = remoteConfig.getString('min_version_ios');
      final String minVersionAndroid = remoteConfig.getString('min_version_android');
      
      // Determine which platform we're on
      final String minRequiredVersion = Platform.isIOS ? minVersionIOS : minVersionAndroid;
      
      print('VersionChecker: Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      print('VersionChecker: Current version: $currentVersion');
      print('VersionChecker: Minimum required version: $minRequiredVersion');
      
      // Compare versions
      if (minRequiredVersion.isEmpty) {
        // If not set in Remote Config, no update required
        return false;
      }
      
      return _isVersionLower(currentVersion, minRequiredVersion);
    } catch (e) {
      print('VersionChecker: Error checking version: $e');
      // On error, don't force update
      return false;
    }
  }
  
  /// Compare two version strings
  /// Returns true if current version is lower than required version
  static bool _isVersionLower(String currentVersion, String requiredVersion) {
    try {
      List<int> currentParts = currentVersion.split('.').map((e) => int.parse(e)).toList();
      List<int> requiredParts = requiredVersion.split('.').map((e) => int.parse(e)).toList();
      
      // Pad with zeros if needed
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (requiredParts.length < 3) {
        requiredParts.add(0);
      }
      
      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < requiredParts[i]) {
          return true; // Current version is lower
        } else if (currentParts[i] > requiredParts[i]) {
          return false; // Current version is higher
        }
      }
      
      return false; // Versions are equal
    } catch (e) {
      print('VersionChecker: Error comparing versions: $e');
      return false;
    }
  }
  
  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('VersionChecker: Error getting current version: $e');
      return 'Unknown';
    }
  }
  
  /// Get minimum required version from Remote Config
  static Future<String> getMinimumRequiredVersion() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      
      final String minVersionIOS = remoteConfig.getString('min_version_ios');
      final String minVersionAndroid = remoteConfig.getString('min_version_android');
      
      // Return version based on current platform
      return Platform.isIOS ? minVersionIOS : minVersionAndroid;
    } catch (e) {
      print('VersionChecker: Error getting minimum version: $e');
      return '';
    }
  }
  
  /// Get store URL for current platform
  static String getStoreUrl() {
    if (Platform.isIOS) {
      // Replace with your actual App Store ID
      return 'https://apps.apple.com/se/app/algebrona/id6475012875';
    } else {
      // Replace with your actual package name
      return 'https://play.google.com/store/apps/details?id=com.aj.algebrona&hl=sv&pli=1';
    }
  }
}

