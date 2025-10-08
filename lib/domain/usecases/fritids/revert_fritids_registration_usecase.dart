import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_fritids_repository.dart';
import '../../repositories/i_student_repository.dart';
import '../../repositories/i_auth_repository.dart';
import '../base_usecase.dart';

/// Parameters for reverting a fritids registration
class RevertFritidsRegistrationParams extends Params {
  final String registrationId;

  const RevertFritidsRegistrationParams({
    required this.registrationId,
  });

  @override
  Map<String, dynamic> toMap() => {
        'registrationId': registrationId,
      };
}

/// Use case for reverting a fritids registration
@lazySingleton
class RevertFritidsRegistrationUseCase
    extends BaseUseCase<bool, RevertFritidsRegistrationParams> {
  final IFritidsRepository _fritidsRepository;
  final IStudentRepository _studentRepository;
  final IAuthRepository _authRepository;

  RevertFritidsRegistrationUseCase(
    this._fritidsRepository,
    this._studentRepository,
    this._authRepository,
  );

  @override
  Future<Result<bool>> call(RevertFritidsRegistrationParams params) async {
    try {
      // Get current staff member
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        return const Failure(
          ValidationError(
            message: 'Du måste vara inloggad',
            code: 'NOT_AUTHENTICATED',
          ),
        );
      }

      // Get the registration details
      final registration = await _fritidsRepository.getRegistrationById(
        params.registrationId,
      );

      if (registration == null) {
        return const Failure(
          NotFoundError(
            message: 'Registreringen hittades inte',
            code: 'REGISTRATION_NOT_FOUND',
          ),
        );
      }

      if (registration.isReverted) {
        return const Failure(
          ValidationError(
            message: 'Registreringen har redan ångrats',
            code: 'ALREADY_REVERTED',
          ),
        );
      }

      // Revert the registration
      final success = await _fritidsRepository.revertRegistration(
        params.registrationId,
        currentUser.uid,
      );

      if (!success) {
        return const Failure(
          UnknownError(
            message: 'Kunde inte ångra registreringen',
            code: 'REVERT_FAILED',
          ),
        );
      }

      // Deduct the algebrona that was awarded
      await _studentRepository.updateStudentCoins(
        uid: registration.studentId,
        coinChange: -registration.algebronaAwarded,
      );

      return const Success(true);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid ångrande av registrering',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
