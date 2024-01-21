import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../other/network_alert.dart';
import '../provider/connectivity_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppleSignInProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> appleLogin(BuildContext context,
      ConnectivityController connectivityController) async {
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

      String displayName = _user?.displayName ?? '';
      String displayNameLower = displayName.toLowerCase();

      if (displayName.isEmpty) {
        displayName = await _promptForDisplayName(context);
        displayNameLower = displayName.toLowerCase();
        await _user!.updateProfile(displayName: displayName);
      }

      Map<String, dynamic> userData = {
        'email': email,
        'displayName': displayName,
        'displayNameLower': displayNameLower,
        'role': 'student',
        'classNumber': 0,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
      };

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        await docRef.set(userData);
      } else {
        await docRef.update(userData);
      }

      // Fetch the feature flag
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        await appleLogout();
        throw Exception('Access denied for unauthorized domain.');
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
    }

    notifyListeners();
  }

  Future<String> _promptForDisplayName(BuildContext context) async {
    String displayName = '';
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Enter Display Name'),
          content: TextField(
            onChanged: (value) {
              displayName = value;
            },
            decoration: InputDecoration(hintText: "Display Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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

      // Fetch the feature flag
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
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
