import 'package:firebase_auth/firebase_auth.dart';

/// Interface for authentication repository
/// Defines all authentication-related operations
abstract class IAuthRepository {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;
  
  /// Get current user
  User? get currentUser;
  
  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  /// Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
  });
  
  /// Sign in with Google
  Future<User?> signInWithGoogle();
  
  /// Sign out
  Future<void> signOut();
  
  /// Delete user account
  Future<void> deleteAccount();
  
  /// Link email/password credential to existing account
  Future<bool> linkEmailPasswordCredential({
    required String email,
    required String password,
  });
  
  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);
  
  /// Update user password
  Future<bool> updatePassword(String newPassword);
  
  /// Check which providers are linked to an email
  Future<List<String>> getProvidersForEmail(String email);
  
  /// Check if email domain is allowed for registration/login
  Future<bool> isEmailDomainAllowed(String email);
}