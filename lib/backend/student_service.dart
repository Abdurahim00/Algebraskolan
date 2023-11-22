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
        print("No students found for class number: $classNumber");
        return [];
      }
    } catch (error) {
      print(
          "An error occurred while fetching students in StudentService: $error");
      rethrow;
    }
  }

  // Search students by display name
  Future<List<Student>> searchStudentsByDisplayName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('displayNameLower',
              isGreaterThanOrEqualTo: query.toLowerCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Student.fromDocument(doc)).toList();
      } else {
        print("No results found for query: $query");
        return [];
      }
    } catch (error) {
      print(
          "An error occurred while searching students in StudentService: $error");
      rethrow;
    }
  }

  Future<bool> updateStudentCoinsInFirestore(String uid, int coins) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'coins': FieldValue.increment(coins)});

      return true;
    } catch (e) {
      print("Error updating coins in StudentService: $e");
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
}
