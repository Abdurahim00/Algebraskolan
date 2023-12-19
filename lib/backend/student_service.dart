import 'package:algebra/backend/coin_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../page/student.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService(this._firestore);

  // Fetch students by class number
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
      rethrow;
    }
  }

  // Fetch all students
  Future<List<Student>> fetchAllStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Student>> searchStudentsByDisplayName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Adjust the query to include class number
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('displayNameLower',
              isGreaterThanOrEqualTo: query.toLowerCase())
          .get();

      List<Student> initialResults =
          snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();

      // Further filter the results if the query is numeric
      if (isNumeric(query)) {
        int classNumber = int.parse(query);
        initialResults = initialResults
            .where((student) => student.classNumber == classNumber)
            .toList();
      }

      return initialResults;
    } catch (error) {
      rethrow;
    }
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  Future<bool> updateStudentCoinsInFirestore(String uid, int coins) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'coins': FieldValue.increment(coins)});

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addTransactionToStudent(
      String uid, CoinTransaction transaction) async {
    Map<String, dynamic> transactionMap = {
      'teacherName': transaction.teacherName,
      'amount': transaction.amount,
      'timestamp': transaction.timestamp,
      'isNew': true,
    };

    await _firestore
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .add(transactionMap);
  }

  // Batch update coins for multiple students and return the UIDs of updated students
  Future<List<String>> updateCoinsForMultipleStudents(
      Map<String, int> studentCoinsUpdates) async {
    WriteBatch batch = _firestore.batch();
    List<String> updatedStudentUids = [];

    try {
      studentCoinsUpdates.forEach((uid, coins) {
        DocumentReference docRef = _firestore.collection('users').doc(uid);
        batch.update(docRef, {'coins': FieldValue.increment(coins)});
        updatedStudentUids.add(uid); // Add the uid to the list
      });
      await batch.commit();
      return updatedStudentUids; // Return the list of updated UIDs
    } catch (e) {
      print('Error in batch update: $e');
      return []; // Return an empty list in case of error
    }
  }

  // Fetch the current coin balance of a student
  Future<int> fetchCurrentCoinBalance(String uid) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (snapshot.exists && data != null && data.containsKey('coins')) {
        return data['coins'] as int;
      } else {
        throw Exception('Student not found or coins field is missing');
      }
    } catch (e) {
      print('Error fetching coin balance: $e');
      rethrow;
    }
  }
}
