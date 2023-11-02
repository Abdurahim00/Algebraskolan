import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final FirebaseFirestore _firestore;

  TransactionService(this._firestore);

  Future<QuerySnapshot> fetchTransactions(String uid) async {
    return await _firestore
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<void> updateTransactionIsNewFlag(String uid, String docId) async {
    await _firestore
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .doc(docId)
        .update({'isNew': false});
  }

  Future<void> logTransaction(String uid, int coins, String teacherName) async {
    await _firestore
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .add({
      'teacherName': teacherName,
      'amount': coins,
      'timestamp': FieldValue.serverTimestamp(),
      'isNew': true,
    });
  }
}
