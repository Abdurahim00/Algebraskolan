import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_student_repository.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/coin_transaction_model.dart';

/// Firestore implementation of IStudentRepository
@LazySingleton(as: IStudentRepository)
class FirestoreStudentRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;
  
  FirestoreStudentRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<StudentModel>> fetchStudentsByClassNumber(int classNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('classNumber', isEqualTo: classNumber)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), id: doc.id))
          .where((student) => student.role == 'student')
          .toList();
    } catch (e) {
      print('FirestoreStudentRepository - fetchStudentsByClassNumber error: $e');
      rethrow;
    }
  }

  @override
  Future<List<StudentModel>> fetchAllStudents() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), id: doc.id))
          .where((student) => student.role == 'student')
          .toList();
    } catch (e) {
      print('FirestoreStudentRepository - fetchAllStudents error: $e');
      rethrow;
    }
  }

  @override
  Future<List<StudentModel>> searchStudentsByDisplayName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('displayNameLower', isLessThan: query.toLowerCase() + 'z')
          .get();

      List<StudentModel> results = snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), id: doc.id))
          .where((student) => student.role == 'student')
          .toList();

      // Additional filtering for numeric queries (class number)
      if (_isNumeric(query)) {
        int classNumber = int.parse(query);
        results = results
            .where((student) => student.classNumber == classNumber)
            .toList();
      }

      return results;
    } catch (e) {
      print('FirestoreStudentRepository - searchStudentsByDisplayName error: $e');
      rethrow;
    }
  }

  @override
  Future<StudentModel?> getStudentById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      return StudentModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      print('FirestoreStudentRepository - getStudentById error: $e');
      return null;
    }
  }

  @override
  Future<bool> updateStudentCoins({
    required String uid,
    required int coinChange,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'coins': FieldValue.increment(coinChange)});

      return true;
    } catch (e) {
      print('FirestoreStudentRepository - updateStudentCoins error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> updateCoinsForMultipleStudents(
    Map<String, int> studentCoinsUpdates,
  ) async {
    WriteBatch batch = _firestore.batch();
    List<String> updatedStudentUids = [];

    try {
      studentCoinsUpdates.forEach((uid, coins) {
        DocumentReference docRef = _firestore.collection('users').doc(uid);
        batch.update(docRef, {'coins': FieldValue.increment(coins)});
        updatedStudentUids.add(uid);
      });
      
      await batch.commit();
      return updatedStudentUids;
    } catch (e) {
      print('FirestoreStudentRepository - updateCoinsForMultipleStudents error: $e');
      return [];
    }
  }

  @override
  Future<int> fetchCurrentCoinBalance(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      
      if (!snapshot.exists) {
        throw Exception('Student not found');
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('coins')) {
        return data['coins'] as int;
      }
      
      throw Exception('Coins field is missing');
    } catch (e) {
      print('FirestoreStudentRepository - fetchCurrentCoinBalance error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection('users')
          .doc(student.uid)
          .update(student.toMap());
      
      return true;
    } catch (e) {
      print('FirestoreStudentRepository - updateStudent error: $e');
      return false;
    }
  }

  @override
  Future<void> deleteStudentDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('Student document deleted successfully');
    } catch (e) {
      print('FirestoreStudentRepository - deleteStudentDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createOrUpdateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection('users')
          .doc(student.uid)
          .set(student.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('FirestoreStudentRepository - createOrUpdateStudent error: $e');
      rethrow;
    }
  }

  @override
  Stream<StudentModel?> watchStudent(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return StudentModel.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClass(int classNumber) {
    return _firestore
        .collection('users')
        .where('classNumber', isEqualTo: classNumber)
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  bool _isNumeric(String s) {
    return double.tryParse(s) != null;
  }
}