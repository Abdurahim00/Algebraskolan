import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/coin_transaction_model.dart';
import '../../repositories/i_transaction_repository.dart';
import '../base_usecase.dart';

/// Parameters for fetching transactions
class FetchTransactionsParams extends Params {
  final String studentId;
  final int? limit;

  const FetchTransactionsParams({
    required this.studentId,
    this.limit,
  });

  @override
  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'limit': limit,
  };
}

/// Use case for fetching student transactions
@lazySingleton
class FetchTransactionsUseCase extends BaseUseCase<List<CoinTransactionModel>, FetchTransactionsParams> {
  final ITransactionRepository _transactionRepository;

  FetchTransactionsUseCase(this._transactionRepository);

  @override
  Future<Result<List<CoinTransactionModel>>> call(FetchTransactionsParams params) async {
    try {
      // Validate student ID
      if (params.studentId.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Student-ID saknas',
            code: 'MISSING_STUDENT_ID',
          ),
        );
      }

      List<CoinTransactionModel> transactions;

      if (params.limit != null) {
        // Fetch paginated transactions
        transactions = await _transactionRepository.fetchTransactionsPaginated(
          studentId: params.studentId,
          limit: params.limit!,
          lastTransaction: null,
        );
      } else {
        // Fetch all transactions
        transactions = await _transactionRepository.fetchAllTransactions(params.studentId);
      }

      return Success(transactions);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Kunde inte hämta transaktioner',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Use case for getting transaction statistics
@lazySingleton
class GetTransactionStatsUseCase extends BaseUseCase<Map<String, dynamic>, FetchTransactionsParams> {
  final ITransactionRepository _transactionRepository;

  GetTransactionStatsUseCase(this._transactionRepository);

  @override
  Future<Result<Map<String, dynamic>>> call(FetchTransactionsParams params) async {
    try {
      // Validate student ID
      if (params.studentId.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Student-ID saknas',
            code: 'MISSING_STUDENT_ID',
          ),
        );
      }

      final stats = await _transactionRepository.getTransactionStats(params.studentId);
      return Success(stats);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Kunde inte hämta transaktionsstatistik',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}