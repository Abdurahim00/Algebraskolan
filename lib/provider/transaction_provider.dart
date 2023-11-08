import 'package:algebra/backend/transaction_service.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final GoogleSignInProvider googleSignInProvider;
  final TransactionService _transactionService = TransactionService();
  String latestDonationMessage = '';
  bool hasLatestDonationBeenShown = false;

  TransactionProvider({this.uid, required this.googleSignInProvider});

  final String? uid;

  Future<void> fetchAndUpdateTransactions() async {
    await _transactionService.fetchAndUpdateTransactions(uid!, (message) {
      latestDonationMessage = message;
      print('Latest donation message: $latestDonationMessage');
      hasLatestDonationBeenShown = false;
      notifyListeners();
    });
  }

  Future<void> updateTransactionIsNewFlag(String docId) async {
    try {
      // Delegate the database update to the TransactionService
      await _transactionService.updateTransactionIsNewFlag(uid!, docId);
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

  Future<void> logTransaction(int coins, String teacherName) async {
    await _transactionService.logTransaction(uid!, coins, teacherName);
  }
}
