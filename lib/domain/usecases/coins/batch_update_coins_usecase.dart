import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_student_repository.dart';
import '../../repositories/i_transaction_repository.dart';
import '../base_usecase.dart';

/// Parameters for batch updating coins
class BatchUpdateCoinsParams extends Params {
  final Map<String, int> studentCoinsUpdates;
  final String teacherName;

  const BatchUpdateCoinsParams({
    required this.studentCoinsUpdates,
    required this.teacherName,
  });

  @override
  Map<String, dynamic> toMap() => {
    'studentCount': studentCoinsUpdates.length,
    'teacherName': teacherName,
    'totalCoins': studentCoinsUpdates.values.fold<int>(0, (sum, coins) => sum + coins),
  };
}

/// Result of batch coin update
class BatchUpdateResult {
  final List<String> successfulUpdates;
  final List<String> failedUpdates;
  final int totalCoinsDistributed;

  const BatchUpdateResult({
    required this.successfulUpdates,
    required this.failedUpdates,
    required this.totalCoinsDistributed,
  });

  bool get allSuccessful => failedUpdates.isEmpty;
  bool get hasFailures => failedUpdates.isNotEmpty;
  int get successCount => successfulUpdates.length;
  int get failureCount => failedUpdates.length;
}

/// Use case for batch updating student coins
@lazySingleton
class BatchUpdateCoinsUseCase extends BaseUseCase<BatchUpdateResult, BatchUpdateCoinsParams> {
  final IStudentRepository _studentRepository;
  final ITransactionRepository _transactionRepository;

  BatchUpdateCoinsUseCase(
    this._studentRepository,
    this._transactionRepository,
  );

  @override
  Future<Result<BatchUpdateResult>> call(BatchUpdateCoinsParams params) async {
    try {
      // Validate input
      if (params.studentCoinsUpdates.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Inga studenter valda',
            code: 'NO_STUDENTS_SELECTED',
          ),
        );
      }

      // Filter out zero coin updates
      final validUpdates = Map<String, int>.from(params.studentCoinsUpdates)
        ..removeWhere((_, coins) => coins == 0);

      if (validUpdates.isEmpty) {
        return const Failure(
          ValidationError(
            message: 'Inga giltiga myntuppdateringar',
            code: 'NO_VALID_UPDATES',
          ),
        );
      }

      // Perform batch update
      final updatedStudentIds = await _studentRepository.updateCoinsForMultipleStudents(
        validUpdates,
      );

      // Log transactions for successful updates
      if (updatedStudentIds.isNotEmpty) {
        final successfulUpdates = Map<String, int>.from(validUpdates)
          ..removeWhere((uid, _) => !updatedStudentIds.contains(uid));

        await _transactionRepository.batchLogTransactions(
          studentCoinsUpdates: successfulUpdates,
          teacherName: params.teacherName,
        );
      }

      // Calculate failed updates
      final failedUpdates = validUpdates.keys
          .where((uid) => !updatedStudentIds.contains(uid))
          .toList();

      // Calculate total coins distributed
      final totalCoinsDistributed = updatedStudentIds.fold<int>(
        0,
        (sum, uid) => sum + (validUpdates[uid] ?? 0),
      );

      return Success(
        BatchUpdateResult(
          successfulUpdates: updatedStudentIds,
          failedUpdates: failedUpdates,
          totalCoinsDistributed: totalCoinsDistributed,
        ),
      );
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid batchuppdatering av mynt',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}