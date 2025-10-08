import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/batch_transaction_model.dart';
import '../../repositories/i_transaction_repository.dart';
import '../base_usecase.dart';

/// Parameters for reverting a batch transaction
class RevertBatchTransactionParams extends Params {
  final String batchId;
  final String teacherId;

  const RevertBatchTransactionParams({
    required this.batchId,
    required this.teacherId,
  });

  @override
  Map<String, dynamic> toMap() => {
    'batchId': batchId,
    'teacherId': teacherId,
  };
}

/// Parameters for getting the last batch transaction
class GetLastBatchTransactionParams extends Params {
  final String teacherId;

  const GetLastBatchTransactionParams({
    required this.teacherId,
  });

  @override
  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
  };
}

/// Use case for reverting a batch transaction
@lazySingleton
class RevertBatchTransactionUseCase extends BaseUseCase<bool, RevertBatchTransactionParams> {
  final ITransactionRepository _transactionRepository;

  RevertBatchTransactionUseCase(this._transactionRepository);

  @override
  Future<Result<bool>> call(RevertBatchTransactionParams params) async {
    try {
      // Validate input
      if (params.batchId.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Batch-ID saknas',
            code: 'MISSING_BATCH_ID',
          ),
        );
      }

      if (params.teacherId.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Lärar-ID saknas',
            code: 'MISSING_TEACHER_ID',
          ),
        );
      }

      // Revert the batch transaction
      final success = await _transactionRepository.revertBatchTransaction(
        params.batchId,
        params.teacherId,
      );

      if (!success) {
        return const Failure(
          UnknownError(
            message: 'Kunde inte ångra transaktionen',
            code: 'REVERT_FAILED',
          ),
        );
      }

      return const Success(true);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett oväntat fel uppstod vid ångrande av transaktion',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Use case for getting the last batch transaction
@lazySingleton
class GetLastBatchTransactionUseCase extends BaseUseCase<BatchTransactionModel?, GetLastBatchTransactionParams> {
  final ITransactionRepository _transactionRepository;

  GetLastBatchTransactionUseCase(this._transactionRepository);

  @override
  Future<Result<BatchTransactionModel?>> call(GetLastBatchTransactionParams params) async {
    try {
      // Validate input
      if (params.teacherId.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Lärar-ID saknas',
            code: 'MISSING_TEACHER_ID',
          ),
        );
      }

      // Get the last batch transaction
      final batchTransaction = await _transactionRepository.getLastBatchTransaction(
        params.teacherId,
      );

      return Success(batchTransaction);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Kunde inte hämta senaste transaktionen',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}