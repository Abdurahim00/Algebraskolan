import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TransactionService {
  TransactionService({@visibleForTesting FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> fetchAndUpdateTransactions(
      String uid, Function(String) onNewTransaction) async {
    if (uid.isEmpty) {
      print("User ID is empty, cannot fetch transactions");
      return;
    }

    QuerySnapshot snapshot = await _firestore
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in snapshot.docs) {
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('isNew') && data['isNew']) {
        final int amount = data['amount'] as int;
        String message = amount >= 0
            ? "${data['teacherName']} +$amount algebronor."
            : "${data['teacherName']} -${amount.abs()} algebronor.";
        onNewTransaction(message);
        await updateTransactionIsNewFlag(uid, doc.id);
        break;
      }
    }
  }

  Future<void> updateTransactionIsNewFlag(String uid, String docId) async {
    try {
      await _firestore
          .collection('students')
          .doc(uid)
          .collection('transactions')
          .doc(docId)
          .update({'isNew': false});
    } catch (e) {
      print('Failed to update transaction: $e');
    }
  }

  Future<void> logTransaction(String uid, int coins, String teacherName) async {
    if (uid.isEmpty) {
      print("Student UID is empty, cannot log transaction");
      return;
    }

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
