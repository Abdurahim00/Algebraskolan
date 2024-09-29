import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final GoogleSignInProvider instance = GoogleSignInProvider._();
  GoogleSignInAccount? _user;
  bool _isLoading = false;

  GoogleSignInAccount? get user => _user;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  bool get isLoading => _isLoading;

  GoogleSignInProvider._();

  Future<void> googleLogin(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

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

      // Sign in with Google credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;
      final email = user.email;
      final displayName = user.displayName;
      final displayNameLower = displayName?.toLowerCase();

      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'allow_all_emails_for_review': false});
      await remoteConfig.fetchAndActivate();
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');

      if (!allowAllEmails &&
          !(email?.endsWith('@algebraskolan.se') ?? false) &&
          !(email?.endsWith('@algebrautbildning.se') ?? false)) {
        throw Exception('Access denied for unauthorized domain.');
      }

      // Check if the user already has an email/password account
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email!,
          password: "Algebraskolan1", // Default password
        );
      } catch (e) {
        // Handle if the email is already in use by an email/password account
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          // The email is already in use, proceed to link Google account to it
          print("Email already has an email/password account.");
        } else {
          print("Error creating email/password account: $e");
        }
      }

      // Link Google account to email/password account
      try {
        await user.linkWithCredential(EmailAuthProvider.credential(
          email: email!,
          password: "Algebraskolan1",
        ));
        print(
            "Google account successfully linked with email/password account.");
      } catch (e) {
        if (e is FirebaseAuthException &&
            e.code == 'credential-already-in-use') {
          print("Google account already linked to the email.");
        } else {
          print("Error linking accounts: $e");
        }
      }

      // Check if user already exists in Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        // Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'displayNameLower': displayNameLower,
          'role': 'student',
          'classNumber': 0,
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
        });
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error during sign-in: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure that the widget tree does not rebuild completely by preserving the screen's state
      await FirebaseAuth.instance.signOut();

      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();

        try {
          await _googleSignIn.disconnect();
        } catch (error) {
          debugPrint('Failed to disconnect: $error');
        }
      }

      // Only notify listeners if the user was actually signed in
      if (_user != null) {
        _user = null;
        notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<bool> isUserSignedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> ensureUserSession() async {
    if (await isUserSignedIn()) {
      await initializeUser();
    } else {
      _user = null;
      notifyListeners();
    }
  }
}
