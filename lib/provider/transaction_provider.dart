import 'package:algebra/backend/transaction_service.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final GoogleSignInProvider googleSignInProvider;
  final TransactionService _transactionService = TransactionService();
  String latestDonationMessage = '';

  TransactionProvider({this.uid, required this.googleSignInProvider});

  final String? uid;

  Future<void> fetchAndUpdateTransactions() async {
    await _transactionService.fetchAndUpdateTransactions(uid!, (message) {
      latestDonationMessage = message;
      notifyListeners();
    });
  }

  Future<void> logTransaction(int coins, String teacherName) async {
    await _transactionService.logTransaction(uid!, coins, teacherName);
  }
}
