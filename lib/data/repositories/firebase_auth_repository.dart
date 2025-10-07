import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_auth_repository.dart';

/// Firebase implementation of IAuthRepository
@LazySingleton(as: IAuthRepository)
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthRepository - signInWithEmailAndPassword error: ${e.code}');
      rethrow;
    } catch (e) {
      print('FirebaseAuthRepository - signInWithEmailAndPassword unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthRepository - registerWithEmailAndPassword error: ${e.code}');
      rethrow;
    } catch (e) {
      print('FirebaseAuthRepository - registerWithEmailAndPassword unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth credentials
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('FirebaseAuthRepository - signInWithGoogle error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogleTokens({
    required String accessToken,
    required String idToken,
  }) async {
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('FirebaseAuthRepository - signInWithGoogleTokens error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Sign out from Google if signed in
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
        try {
          await _googleSignIn.disconnect();
        } catch (e) {
          // Ignore disconnect errors
          print('Google disconnect error (non-critical): $e');
        }
      }
    } catch (e) {
      print('FirebaseAuthRepository - signOut error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user currently signed in');
      }

      // Delete the user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthRepository - deleteAccount error: ${e.code}');
      rethrow;
    } catch (e) {
      print('FirebaseAuthRepository - deleteAccount unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> linkEmailPasswordCredential({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.linkWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthRepository - linkEmailPasswordCredential error: ${e.code}');
      if (e.code == 'provider-already-linked' || 
          e.code == 'credential-already-in-use') {
        return false;
      }
      rethrow;
    } catch (e) {
      print('FirebaseAuthRepository - linkEmailPasswordCredential unexpected error: $e');
      return false;
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check if email exists in Firestore users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('FirebaseAuthRepository - isEmailRegistered error: $e');
      return false;
    }
  }

  @override
  Future<bool> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }

      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthRepository - updatePassword error: ${e.code}');
      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate
        return false;
      }
      rethrow;
    } catch (e) {
      print('FirebaseAuthRepository - updatePassword unexpected error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getProvidersForEmail(String email) async {
    try {
      // Since fetchSignInMethodsForEmail is deprecated, we check Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        // Return providers if stored, otherwise check current user
        if (userData['providers'] != null) {
          return List<String>.from(userData['providers']);
        }
        
        // If the email matches current user, return their providers
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          return currentUser.providerData.map((p) => p.providerId).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('FirebaseAuthRepository - getProvidersForEmail error: $e');
      return [];
    }
  }
  
  @override
  Future<bool> isEmailDomainAllowed(String email) async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'allow_all_emails_for_review': false});
      await remoteConfig.fetchAndActivate();
      bool allowAllEmails = remoteConfig.getBool('allow_all_emails_for_review');
      
      if (allowAllEmails) {
        return true;
      }
      
      // Check if email ends with allowed domains
      return email.endsWith('@algebraskolan.se') || 
             email.endsWith('@algebrautbildning.se');
    } catch (e) {
      print('FirebaseAuthRepository - isEmailDomainAllowed error: $e');
      // Default to restrictive behavior if there's an error
      return email.endsWith('@algebraskolan.se') || 
             email.endsWith('@algebrautbildning.se');
    }
  }
}