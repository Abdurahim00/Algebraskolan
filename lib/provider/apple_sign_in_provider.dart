import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../other/network_alert.dart';
import '../provider/connectivity_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppleSignInProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> appleLogin(BuildContext context,
      ConnectivityController connectivityController) async {
    _isLoading = true;
    notifyListeners();

    try {
      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      _user = userCredential.user;
      final uid = _user?.uid;
      final email = _user?.email;

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

      // Prompt for display name if not provided
      String displayName = _user?.displayName ?? '';
      String displayNameLower = displayName.toLowerCase();

      if (displayName.isEmpty) {
        displayName = await _promptForDisplayName(context);
        displayNameLower = displayName.toLowerCase();
        await _user!.updateDisplayName(displayName);
      }

      // Check if user document exists in Firestore
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create new user document if it doesn't exist
        await docRef.set({
          'email': email,
          'displayName': displayName,
          'displayNameLower': displayNameLower,
          'role': 'student', // Default role
          'classNumber': 0,
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed') {
        NetworkAlertPopup.show(context, connectivityController, () {
          appleLogin(context, connectivityController);
        });
      } else {
        debugPrint('Firebase Exception during sign-in: $e');
      }
    } catch (e) {
      debugPrint('Error during sign-in: $e');
      // Ensure user is logged out and not registered in Firestore if the domain is unauthorized
      await appleLogout();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> _promptForDisplayName(BuildContext context) async {
    String displayName = '';
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ange visningsnamn'),
          content: TextField(
            onChanged: (value) {
              displayName = value;
            },
            decoration: const InputDecoration(hintText: "Visningsnamn"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
    return displayName;
  }

  Future<void> appleLogout() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      final email = _user?.email;
      if (!(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        await appleLogout();
        return false;
      }
    } else {
      return false;
    }
    notifyListeners();
    return true;
  }
}

