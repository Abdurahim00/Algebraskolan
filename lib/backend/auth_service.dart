import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<DocumentSnapshot> getUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<List<Student>> fetchStudents({int? classNumber}) async {
    QuerySnapshot querySnapshot;

    if (classNumber != null) {
      querySnapshot = await _firestore
          .collection('students')
          .where('classNumber', isEqualTo: classNumber)
          .get();
    } else {
      querySnapshot = await _firestore.collection('students').get();
    }

    return querySnapshot.docs.map((doc) => Student.fromDocument(doc)).toList();
  }
}
