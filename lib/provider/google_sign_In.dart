import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../other/network_alert.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../provider/connectivity_provider.dart';

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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      _user = googleUser;
      notifyListeners();

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

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

      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        throw Exception('Access denied for unauthorized domain.');
      }

      // Check for existing documents with the same email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Delete duplicate documents
      for (var doc in querySnapshot.docs) {
        if (doc.id != uid) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .delete();
        }
      }

      // Proceed with the current user's document
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        // Document exists, update it if necessary
        final data = docSnapshot.data() as Map<String, dynamic>;

        if (data['role'] != 'teacher') {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'role': 'teacher',
            'classNumber': -1,
          });
        }
      } else {
        // Create new user document if it doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'displayName': displayName,
          'displayNameLower': displayNameLower,
          'role': 'teacher',
          'classNumber': -1,
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
        });
      }

      // Force a reload of the current user's data
      await FirebaseAuth.instance.currentUser?.reload();
      final reloadedUser = FirebaseAuth.instance.currentUser;
      final updatedDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(reloadedUser?.uid)
          .get();

      if (updatedDocSnapshot.exists) {
        _user = googleUser;
        notifyListeners(); // Trigger UI update after ensuring the document is updated
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (e is FirebaseException && e.code == 'network-request-failed') {
        NetworkAlertPopup.show(context, connectivityController, () {
          googleLogin(context, connectivityController);
        });
      } else {
        debugPrint('Error during sign-in: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
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
