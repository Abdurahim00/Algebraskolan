import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../other/network_alert.dart';
import '../provider/connectivity_provider.dart';
import '/backend/control_page.dart'; // Ensure HomePage is imported correctly

class GoogleSignInProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final GoogleSignInProvider instance = GoogleSignInProvider._();
  GoogleSignInAccount? _user;
  bool _isLoading = false;

  GoogleSignInAccount? get user => _user;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  bool get isLoading => _isLoading;

  GoogleSignInProvider._();

  Future<void> googleLogin(BuildContext context,
      ConnectivityController connectivityController) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting Google Sign-In...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In was canceled by the user.');
        _isLoading = false;
        notifyListeners();
        return;
      }
      _user = googleUser;
      print('Google Sign-In successful: ${googleUser.email}');
      notifyListeners();

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;
      final email = user.email;
      final displayName = user.displayName;
      final displayNameLower = displayName?.toLowerCase();

      print('Firebase Sign-In successful for UID: $uid');

      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'allow_all_emails_for_review': false});
      await remoteConfig.fetchAndActivate();
      print('Remote Config fetched and activated');
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        throw Exception('Access denied for unauthorized domain: $email');
      }

      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!docSnapshot.exists) {
        print('Creating new user document for UID: $uid');
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'displayName': displayName,
          'displayNameLower': displayNameLower,
          'role': 'student',  // Default to 'student'
          'classNumber': 0,
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
        });
      } else {
        final data = docSnapshot.data() as Map<String, dynamic>;
        if (data['role'] == null) {
          print('Updating user role to default "student" for UID: $uid');
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'role': 'student',
          });
        }
      }

      print('Sign-In process completed successfully for ${googleUser.email}');
      
      // Navigate to HomePage using context
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (e is FirebaseException && e.code == 'network-request-failed') {
        print('Network request failed: $e');
        NetworkAlertPopup.show(context, connectivityController, () {
          googleLogin(context, connectivityController);
        });
      } else {
        print('Error during sign-in: $e');
      }
    }
  }

  Future<void> googleLogout() async {
    _isLoading = true;
    notifyListeners();

    await FirebaseAuth.instance.signOut();

    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.signOut();

      try {
        await _googleSignIn.disconnect();
      } catch (error) {
        debugPrint('Failed to disconnect: $error');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    _user = null;
    notifyListeners();
  }

  Future<void> googleDisconnect() async {
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.disconnect();
    }
  }

  Future<bool> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      prefs.setBool('isFirstLaunch', false);
      return false;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.signInSilently();
        if (googleUser != null) {
          _user = googleUser;
          notifyListeners();

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
            return false;
          }

          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (docSnapshot.exists) {
            final userData = docSnapshot.data();
            _user = googleUser;
          }

          return true;
        } else {
          return false;
        }
      } catch (error) {
        debugPrint("Error in silent sign-in: $error");
        return false;
      }
    } else {
      return false;
    }
  }
}
