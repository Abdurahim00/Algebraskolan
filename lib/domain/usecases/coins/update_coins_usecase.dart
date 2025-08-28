import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/coin_transaction_model.dart';
import '../../repositories/i_student_repository.dart';
import '../../repositories/i_transaction_repository.dart';
import '../base_usecase.dart';

/// Parameters for updating coins
class UpdateCoinsParams extends Params {
  final String studentId;
  final int coinAmount;
  final String teacherName;
  final String? description;

  const UpdateCoinsParams({
    required this.studentId,
    required this.coinAmount,
    required this.teacherName,
    this.description,
  });

  @override
  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'coinAmount': coinAmount,
    'teacherName': teacherName,
    'description': description,
  };
}

/// Use case for updating student coins
@lazySingleton
class UpdateCoinsUseCase extends BaseUseCase<bool, UpdateCoinsParams> {
  final IStudentRepository _studentRepository;
  final ITransactionRepository _transactionRepository;

  UpdateCoinsUseCase(
    this._studentRepository,
    this._transactionRepository,
  );

  @override
  Future<Result<bool>> call(UpdateCoinsParams params) async {
    try {
      // Validate coin amount
      if (params.coinAmount == 0) {
        return const Failure(
          ValidationError(
            message: 'Myntbeloppet kan inte vara 0',
            code: 'INVALID_AMOUNT',
          ),
        );
      }

      // Check if student exists
      final student = await _studentRepository.getStudentById(params.studentId);
      if (student == null) {
        return const Failure(
          NotFoundError(
            message: 'Studenten hittades inte',
            code: 'STUDENT_NOT_FOUND',
          ),
        );
      }

      // Check if student has enough coins for deduction
      if (params.coinAmount < 0) {
        final currentBalance = await _studentRepository.fetchCurrentCoinBalance(params.studentId);
        if (currentBalance + params.coinAmount < 0) {
          return const Failure(
            ValidationError(
              message: 'Otillräckligt saldo',
              code: 'INSUFFICIENT_BALANCE',
            ),
          );
        }
      }

      // Update coins
      final success = await _studentRepository.updateStudentCoins(
        uid: params.studentId,
        coinChange: params.coinAmount,
      );

      if (!success) {
        return const Failure(
          UnknownError(
            message: 'Kunde inte uppdatera mynt',
            code: 'UPDATE_FAILED',
          ),
        );
      }

      // Log transaction
      await _transactionRepository.logTransaction(
        studentId: params.studentId,
        coins: params.coinAmount,
        teacherName: params.teacherName,
      );

      return const Success(true);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid uppdatering av mynt',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}