import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'coin_transaction.dart';

class TransactionService {
  TransactionService({@visibleForTesting FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> fetchAndUpdateTransactions(
      String uid, Function(String) onNewTransaction) async {
    if (uid.isEmpty) {
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .doc(uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(1) // Fetch only the latest transaction
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final int amount = data['amount'] as int;
          String message = amount >= 0
              ? "${data['teacherName']} +$amount algebronor."
              : "${data['teacherName']} -${amount.abs()} algebronor.";
          onNewTransaction(message);
        }
      }
    } catch (e) {
      print('Error fetching latest transaction: $e');
    }
  }

  Future<void> logTransaction(String uid, int coins, String teacherName) async {
    if (uid.isEmpty) {
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
    });
  }

  Future<List<CoinTransaction>> fetchAllTransactions(String uid) async {
    List<CoinTransaction> transactions = [];
    if (uid.isEmpty) {
      return transactions;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .doc(uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        transactions.add(CoinTransaction.fromMap(data));
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }

    return transactions;
  }
}
