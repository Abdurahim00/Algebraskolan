import '../models/coin_transaction_model.dart';
import '../models/batch_transaction_model.dart';

/// Interface for transaction repository
/// Defines all transaction-related operations
abstract class ITransactionRepository {
  /// Add a new transaction
  Future<void> addTransaction({
    required String studentId,
    required CoinTransactionModel transaction,
  });
  
  /// Fetch all transactions for a student
  Future<List<CoinTransactionModel>> fetchAllTransactions(String studentId);
  
  /// Fetch latest transaction for a student
  Future<CoinTransactionModel?> fetchLatestTransaction(String studentId);
  
  /// Fetch transactions with pagination
  Future<List<CoinTransactionModel>> fetchTransactionsPaginated({
    required String studentId,
    required int limit,
    CoinTransactionModel? lastTransaction,
  });
  
  /// Log transaction for a student
  Future<void> logTransaction({
    required String studentId,
    required int coins,
    required String teacherName,
  });
  
  /// Batch log transactions for multiple students
  Future<void> batchLogTransactions({
    required Map<String, int> studentCoinsUpdates,
    required String teacherName,
  });
  
  /// Stream of transactions for a student
  Stream<List<CoinTransactionModel>> watchTransactions(String studentId);
  
  /// Delete all transactions for a student
  Future<void> deleteAllTransactions(String studentId);
  
  /// Get transaction statistics for a student
  Future<Map<String, dynamic>> getTransactionStats(String studentId);

  /// Save a batch transaction
  Future<String> saveBatchTransaction(BatchTransactionModel batch);

  /// Get the last batch transaction for a teacher
  Future<BatchTransactionModel?> getLastBatchTransaction(String teacherId);

  /// Revert a batch transaction
  Future<bool> revertBatchTransaction(String batchId, String teacherId);
}