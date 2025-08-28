import 'package:flutter/foundation.dart';
import '../backend/coin_transaction.dart';
import '../core/di/injection_container.dart';
import '../core/result/result.dart';
import '../domain/models/coin_transaction_model.dart';
import '../domain/usecases/coins/fetch_transactions_usecase.dart';
import '../domain/usecases/coins/update_coins_usecase.dart';
import '../provider/google_sign_In.dart';

class TransactionProvider extends ChangeNotifier {
  final GoogleSignInProvider googleSignInProvider;
  String latestDonationMessage = '';
  List<CoinTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  TransactionProvider({this.uid, required this.googleSignInProvider});

  final String? uid;
  
  List<CoinTransaction> get transactions => [..._transactions];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Convert domain model to legacy CoinTransaction model
  CoinTransaction _domainToLegacyTransaction(CoinTransactionModel domainTransaction) {
    return CoinTransaction(
      teacherName: domainTransaction.teacherName,
      amount: domainTransaction.amount,
      timestamp: domainTransaction.timestamp,
    );
  }

  Future<void> fetchAndUpdateTransactions() async {
    if (uid == null) {
      _errorMessage = 'Ingen användare inloggad';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchTransactionsUseCase = InjectionContainer.fetchTransactionsUseCase;
      final result = await fetchTransactionsUseCase(
        FetchTransactionsParams(
          studentId: uid!,
          limit: 50, // Fetch recent 50 transactions
        ),
      );

      result.fold(
        onSuccess: (transactionsList) {
          _transactions = transactionsList
              .map((t) => _domainToLegacyTransaction(t))
              .toList();
          
          // Update latest donation message if there are transactions
          if (transactionsList.isNotEmpty) {
            final latestTransaction = transactionsList.first;
            latestDonationMessage = _formatDonationMessage(latestTransaction);
          }
          
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (error) {
          _errorMessage = error.message;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Ett oväntat fel uppstod';
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatDonationMessage(CoinTransactionModel transaction) {
    final isPositive = transaction.amount > 0;
    final coinText = isPositive ? '+${transaction.amount}' : '${transaction.amount}';
    final action = isPositive ? 'fick' : 'förlorade';
    return 'Du $action $coinText mynt från ${transaction.teacherName}';
  }

  Future<void> logTransaction(int coins, String teacherName) async {
    if (uid == null) {
      _errorMessage = 'Ingen användare inloggad';
      notifyListeners();
      return;
    }

    try {
      final updateCoinsUseCase = InjectionContainer.updateCoinsUseCase;
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: uid!,
          coinAmount: coins,
          teacherName: teacherName,
        ),
      );

      result.fold(
        onSuccess: (_) {
          // Refresh transactions after logging new one
          fetchAndUpdateTransactions();
        },
        onFailure: (error) {
          _errorMessage = error.message;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Kunde inte logga transaktion';
      notifyListeners();
    }
  }

  Future<List<CoinTransaction>> fetchAllUserTransactions() async {
    if (uid == null) {
      _errorMessage = 'Ingen användare inloggad';
      return [];
    }

    try {
      final fetchTransactionsUseCase = InjectionContainer.fetchTransactionsUseCase;
      final result = await fetchTransactionsUseCase(
        FetchTransactionsParams(
          studentId: uid!,
        ),
      );

      return result.fold(
        onSuccess: (transactionsList) {
          _transactions = transactionsList
              .map((t) => _domainToLegacyTransaction(t))
              .toList();
          return _transactions;
        },
        onFailure: (error) {
          _errorMessage = error.message;
          return [];
        },
      );
    } catch (e) {
      _errorMessage = 'Kunde inte hämta transaktioner';
      return [];
    }
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    if (uid == null) {
      _errorMessage = 'Ingen användare inloggad';
      return {};
    }

    try {
      final getStatsUseCase = InjectionContainer.transactionStatsUseCase;
      final result = await getStatsUseCase(
        FetchTransactionsParams(
          studentId: uid!,
        ),
      );

      return result.fold(
        onSuccess: (stats) => stats,
        onFailure: (error) {
          _errorMessage = error.message;
          return {};
        },
      );
    } catch (e) {
      _errorMessage = 'Kunde inte hämta statistik';
      return {};
    }
  }

  void clearTransactions() {
    _transactions.clear();
    latestDonationMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}