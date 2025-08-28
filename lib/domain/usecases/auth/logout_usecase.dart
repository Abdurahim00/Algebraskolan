import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_auth_repository.dart';
import '../base_usecase.dart';

/// Use case for user logout
@lazySingleton
class LogoutUseCase extends NoParamsUseCase<void> {
  final IAuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  @override
  Future<Result<void>> call() async {
    try {
      await _authRepository.signOut();
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid utloggning',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}