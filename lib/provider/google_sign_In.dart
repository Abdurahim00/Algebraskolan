import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../other/network_alert.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../provider/connectivity_provider.dart'; // Import ConnectivityProvider

class GoogleSignInProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final GoogleSignInProvider instance = GoogleSignInProvider._();
  GoogleSignInAccount? _user;

  GoogleSignInAccount? get user => _user;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  GoogleSignInProvider._(); // Private constructor

  Future<void> googleLogin(BuildContext context,
      ConnectivityController connectivityController) async {
    try {
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      _user = googleUser;
      notifyListeners();

      // Get authentication credentials
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;
      final email = user.email;
      final displayName = user.displayName;
      final displayNameLower =
          displayName?.toLowerCase(); // Lowercase display name

      // Fetch the feature flag
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'allow_all_emails_for_review': false});
      await remoteConfig.fetchAndActivate();
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

      // Check if the email domain is allowed
      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        throw Exception('Access denied for unauthorized domain.');
      }
      // Check if user document exists in Firestore
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        // Create new user document if it doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'displayName': displayName,
          'displayNameLower': displayNameLower, // Add displayNameLower field
          'role': 'student', // Default role
          'classNumber': 0,
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
        });
      }
    } catch (e) {
      // Handle network exceptions
      if (e is FirebaseException && e.code == 'network-request-failed') {
        // Show network alert dialog with a retry callback
        NetworkAlertPopup.show(context, connectivityController, () {
          // Retry logic for Google login
          googleLogin(context, connectivityController);
        });
      } else {
        // Handle other exceptions including unauthorized domain access
        Exception('Error during sign-in: $e');
        // Show error message or perform other actions
      }
    }

    // Notify listeners of any changes
    notifyListeners();
  }

  Future<void> googleLogout() async {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    if (_googleSignIn.currentUser != null) {
      // Sign out from Google Sign-In
      await _googleSignIn.signOut();

      // Disconnect from Google Sign-In
      try {
        await _googleSignIn.disconnect();
      } catch (error) {
        Exception('Failed to disconnect: $error');
      }
    }

    // Set user to null
    _user = null;

    // Notify listeners of changes
    notifyListeners();
  }

  Future<void> googleDisconnect() async {
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.disconnect();
    }
  }

  Future<bool> initializeUser() async {
    // Check if this is the first launch after installation
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      // If it's the first launch, clear any existing authentication state
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      prefs.setBool('isFirstLaunch', false);
      return false; // User needs to sign in again
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Attempt to sign in with Google silently
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.signInSilently();
        if (googleUser != null) {
          // Update the _user with the Google user
          _user = googleUser;
          notifyListeners();

          // Additional checks for email domains or other conditions
          final email = currentUser.email;
          final FirebaseRemoteConfig remoteConfig =
              FirebaseRemoteConfig.instance;
          await remoteConfig.fetchAndActivate();
          bool allowAllEmails =
              remoteConfig.getBool('allow_all_emails_for_review');

          if (!allowAllEmails &&
              !(email?.endsWith('@algebraskolan.se') ?? false) &&
              !(email?.endsWith('@algebrautbildning.se') ?? false)) {
            await googleLogout();
            return false; // User is not authorized
          }
          return true; // User is authorized and signed in
        } else {
          // No Google user is signed in
          return false;
        }
      } catch (error) {
        debugPrint("Error in silent sign-in: $error");
        return false; // In case of error, consider the user not authorized
      }
    } else {
      // No Firebase user is signed in
      return false;
    }
  }
}
