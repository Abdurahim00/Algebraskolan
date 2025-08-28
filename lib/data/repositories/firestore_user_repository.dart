import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_user_repository.dart';

/// Firestore implementation of IUserRepository
@LazySingleton(as: IUserRepository)
class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;
  
  FirestoreUserRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DocumentSnapshot?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('FirestoreUserRepository - getUserDocument error: $e');
      return null;
    }
  }

  @override
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String role,
    int classNumber = 0,
    int coins = 0,
    bool hasAnsweredQuestionCorrectly = false,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        'role': role,
        'classNumber': classNumber,
        'coins': coins,
        'hasAnsweredQuestionCorrectly': hasAnsweredQuestionCorrectly,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('User document created successfully for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - createUserDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserDocument({
    required String uid,
    Map<String, dynamic>? updates,
  }) async {
    if (updates == null || updates.isEmpty) {
      return;
    }

    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(updates);
      print('User document updated successfully for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - updateUserDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('User document deleted successfully for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - deleteUserDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('FirestoreUserRepository - userDocumentExists error: $e');
      return false;
    }
  }

  @override
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['role'] as String?;
    } catch (e) {
      print('FirestoreUserRepository - getUserRole error: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('User role updated to $role for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - updateUserRole error: $e');
      rethrow;
    }
  }

  @override
  Future<DocumentSnapshot?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return querySnapshot.docs.first;
    } catch (e) {
      print('FirestoreUserRepository - getUserByEmail error: $e');
      return null;
    }
  }

  @override
  Stream<DocumentSnapshot?> watchUserDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot : null);
  }

  @override
  Future<void> updateUserClass({
    required String uid,
    required int classNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'classNumber': classNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('User class updated to $classNumber for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - updateUserClass error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markQuestionAnswered(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasAnsweredQuestionCorrectly': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Question marked as answered for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - markQuestionAnswered error: $e');
      rethrow;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await getUserDocument(uid);
      if (doc != null && doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('FirestoreUserRepository - getUserData error: $e');
      return null;
    }
  }
  
  @override
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('User data deleted for uid: $uid');
    } catch (e) {
      print('FirestoreUserRepository - deleteUserData error: $e');
      rethrow;
    }
  }
}