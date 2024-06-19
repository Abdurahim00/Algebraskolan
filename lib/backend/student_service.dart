import 'package:algebra/backend/coin_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService(this._firestore);

  Future<List<Student>> fetchStudentsByClassNumber(int classNumber) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('classNumber', isEqualTo: classNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching students by class number: $error');
      rethrow;
    }
  }

  Future<List<Student>> fetchAllStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();
    } catch (error) {
      print('Error fetching all students: $error');
      rethrow;
    }
  }

  Future<List<Student>> searchStudentsByDisplayName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: query.toLowerCase())
          .get();

      List<Student> initialResults = snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();

      if (isNumeric(query)) {
        int classNumber = int.parse(query);
        initialResults = initialResults
            .where((student) => student.classNumber == classNumber)
            .toList();
      }

      return initialResults;
    } catch (error) {
      print('Error searching students by display name: $error');
      rethrow;
    }
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  Future<bool> updateStudentCoinsInFirestore(String uid, int coins) async {
    try {
      await _firestore.collection('users').doc(uid).update({'coins': FieldValue.increment(coins)});
      return true;
    } catch (e) {
      print('Error updating student coins: $e');
      return false;
    }
  }

  Future<void> addTransactionToStudent(String uid, CoinTransaction transaction) async {
    Map<String, dynamic> transactionMap = {
      'teacherName': transaction.teacherName,
      'amount': transaction.amount,
      'timestamp': transaction.timestamp,
    };

    await _firestore.collection('students').doc(uid).collection('transactions').add(transactionMap);
  }

  Future<List<String>> updateCoinsForMultipleStudents(Map<String, int> studentCoinsUpdates) async {
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
      print('Error updating coins for multiple students: $e');
      return [];
    }
  }

  Future<int> fetchCurrentCoinBalance(String uid) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (snapshot.exists && data != null && data.containsKey('coins')) {
        return data['coins'] as int;
      } else {
        throw Exception('Student not found or coins field is missing');
      }
    } catch (e) {
      print('Error fetching current coin balance: $e');
      rethrow;
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete();
        print("User account deleted successfully.");
      }
    } on FirebaseAuthException catch (e) {
      print("Error deleting user account: ${e.message}");
    }
  }

  Future<void> updateCoinsWithTransaction(String uid, int coinsToChange, String teacherName) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception('Student not found');
      }

      var data = snapshot.data();
      if (data is Map<String, dynamic>) {
        int currentCoins = data['coins'] as int? ?? 0;

        if (currentCoins + coinsToChange < 0) {
          throw Exception('Insufficient coins');
        }

        transaction.update(userRef, {'coins': FieldValue.increment(coinsToChange)});

        CoinTransaction transactionData = CoinTransaction(
          teacherName: teacherName,
          amount: coinsToChange,
          timestamp: DateTime.now(),
        );
        await addTransactionToStudent(uid, transactionData);
      } else {
        throw Exception('Data is not in expected format');
      }
    });
  }

  Future<void> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print("User Firestore document deleted successfully.");
    } catch (e) {
      print("Error deleting user document: $e");
      rethrow;
    }
  }
}
