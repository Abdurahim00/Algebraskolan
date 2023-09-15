import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionProvider extends ChangeNotifier {
  final GoogleSignInProvider googleSignInProvider;
  String latestDonationMessage = '';
  bool hasLatestDonationBeenShown = false;

  TransactionProvider({this.uid, required this.googleSignInProvider});

  final String? uid; // <-- Use the uid from GoogleSignInProvider

  Future<void> fetchAndUpdateTransactions() async {
    if (uid == null || uid!.isEmpty) {
      print("User ID is null or empty, cannot fetch transactions");
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in snapshot.docs) {
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('isNew') && data['isNew']) {
        final int amount =
            data['amount'] as int; // Assuming the amount is stored as int

        // Check if the amount is positive or negative and format the message accordingly
        if (amount >= 0) {
          latestDonationMessage =
              "${data['teacherName']} donated $amount coins.";
        } else {
          latestDonationMessage =
              "${data['teacherName']} deducted ${amount.abs()} coins.";
        }

        print('Latest donation message: $latestDonationMessage');
        await updateTransactionIsNewFlag(doc.id);
        break;
      }
    }
    notifyListeners();
  }

  Future<void> updateTransactionIsNewFlag(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid) // <-- Use the uid from GoogleSignInProvider
          .collection('transactions')
          .doc(docId)
          .update({'isNew': false});
    } catch (e) {
      print('Failed to update transaction: $e');
    }
  }

  void resetLatestDonationMessage() {
    print("resetting latestDonationMessage...");

    // Clear the message after 5 seconds
    // Reset the shown flag
    hasLatestDonationBeenShown = false;

    // Clear the message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      latestDonationMessage = '';
      notifyListeners();
    });
  }

  void markLatestDonationAsShown() {
    hasLatestDonationBeenShown = true;
    print("Marked latest donation as shown"); // Debug print
    notifyListeners();
  }

  Future<void> logTransaction(String uid, int coins, String teacherName) async {
    if (uid.isEmpty) {
      print("Student UID is empty, cannot log transaction");
      return;
    }

    await FirebaseFirestore.instance
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
