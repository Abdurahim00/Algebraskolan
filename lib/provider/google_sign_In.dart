import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final GoogleSignInProvider instance = GoogleSignInProvider._();
  GoogleSignInAccount? _user;

  GoogleSignInAccount? get user => _user;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  GoogleSignInProvider._(); // Private constructor

  Future<void> googleLogin(BuildContext context) async {
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

    try {
      // Sign in to Firebase with Google credentials
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;
      final email = user.email;
      final displayName = user.displayName;

      // Check if user document exists in Firestore
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        // Create new user document if it doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'displayName': displayName,
          'role':
              'student', // everyone who creates an account will become a student, the admin assigns teachers
          'classNumber': 0,
          'coins': 0, // default coins set to 0
          // set to current time
          'hasAnsweredQuestionCorrectly':
              false, // new user has not yet answered a question
        });
      }
    } catch (e) {
      // Handle any exceptions that occur during sign-in
      print('Error during sign-in: $e');
      // You can show an error message or perform any other necessary action
      if (e is FirebaseException && e.code == "NETWORK_ERROR") {
        print("Network error detected!");
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("KOLLA DIN INTERNET")));
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
        print('Failed to disconnect: $error');
      }
    }

    // Set user to null
    _user = null;

    // Notify listeners of changes
    notifyListeners();
  }
}
