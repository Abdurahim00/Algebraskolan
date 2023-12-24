import 'package:algebra/backend/transaction_service.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/foundation.dart';

import '../backend/coin_transaction.dart';

class TransactionProvider extends ChangeNotifier {
  final GoogleSignInProvider googleSignInProvider;
  final TransactionService _transactionService = TransactionService();
  String latestDonationMessage = '';

  TransactionProvider({this.uid, required this.googleSignInProvider});

  final String? uid;

  Future<void> fetchAndUpdateTransactions() async {
    if (uid == null) {
      // Handle the null case, maybe throw an error or return
      return;
    }

    await _transactionService.fetchAndUpdateTransactions(uid!, (message) {
      latestDonationMessage = message;
      notifyListeners();
    });
  }

  Future<void> logTransaction(int coins, String teacherName) async {
    if (uid == null) {
      // Handle the null case, maybe throw an error or return
      return;
    }

    await _transactionService.logTransaction(uid!, coins, teacherName);
  }

  Future<List<CoinTransaction>> fetchAllUserTransactions() async {
    if (uid == null) {
      // Handle the null case, maybe throw an error or return
      return [];
    }

    return await _transactionService.fetchAllTransactions(uid!);
  }
}
