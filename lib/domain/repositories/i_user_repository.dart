import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for user repository
/// Defines all user-related operations
abstract class IUserRepository {
  /// Get user document by UID
  Future<DocumentSnapshot?> getUserDocument(String uid);
  
  /// Create user document
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String role,
    int classNumber = 0,
    int coins = 0,
    bool hasAnsweredQuestionCorrectly = false,
  });
  
  /// Update user document
  Future<void> updateUserDocument({
    required String uid,
    Map<String, dynamic>? updates,
  });
  
  /// Delete user document
  Future<void> deleteUserDocument(String uid);
  
  /// Check if user document exists
  Future<bool> userDocumentExists(String uid);
  
  /// Get user role
  Future<String?> getUserRole(String uid);
  
  /// Update user role
  Future<void> updateUserRole({
    required String uid,
    required String role,
  });
  
  /// Get user by email
  Future<DocumentSnapshot?> getUserByEmail(String email);
  
  /// Stream of user document changes
  Stream<DocumentSnapshot?> watchUserDocument(String uid);
  
  /// Update user class number
  Future<void> updateUserClass({
    required String uid,
    required int classNumber,
  });
  
  /// Mark question as answered correctly
  Future<void> markQuestionAnswered(String uid);
  
  /// Get user data as Map
  Future<Map<String, dynamic>?> getUserData(String uid);
  
  /// Delete user data
  Future<void> deleteUserData(String uid);
}