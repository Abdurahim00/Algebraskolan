import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../other/network_alert.dart';
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

      // Check if the email domain is allowed
      if (!(email?.endsWith('@gmail.com') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        // If the domain is not allowed, throw an exception
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

  Future<bool> initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        _user = await _googleSignIn.signInSilently();
        final email = _user?.email;

        if (!(email?.endsWith('@gmail.com') ?? false) &&
            !(email?.endsWith('@algebrautbildning.se') ?? false)) {
          await googleLogout();
          return false; // User is not authorized
        }
      } catch (error) {
        Exception("Error in silent sign-in: $error");
        return false; // In case of error, consider the user not authorized
      }
    } else {
      return false; // No user is signed in
    }
    notifyListeners();
    return true; // User is authorized and signed in
  }
}
