import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_user_repository.dart';
import '../base_usecase.dart';

/// Parameters for registration use case
class RegisterParams extends Params {
  final String email;
  final String password;
  final String role;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
    'password': '***', // Don't log passwords
  };
}

/// Use case for user registration
@lazySingleton
class RegisterUseCase extends BaseUseCase<User, RegisterParams> {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final FirebaseRemoteConfig _remoteConfig;

  RegisterUseCase(
    this._authRepository,
    this._userRepository,
    this._remoteConfig,
  );

  @override
  Future<Result<User>> call(RegisterParams params) async {
    try {
      // Validate email domain
      final domainValidation = await _validateEmailDomain(params.email);
      if (domainValidation.isFailure) {
        return Failure(domainValidation.errorOrNull!);
      }

      // Check if email already exists in our system
      final existingUser = await _userRepository.getUserByEmail(params.email);
      if (existingUser != null) {
        return const Failure(
          ValidationError(
            message: 'E-postadressen är redan registrerad',
            code: 'EMAIL_ALREADY_EXISTS',
          ),
        );
      }

      // Register the user
      final user = await _authRepository.registerWithEmailAndPassword(
        email: params.email,
        password: params.password,
        role: params.role,
      );

      if (user == null) {
        return const Failure(
          AuthenticationError(
            message: 'Registrering misslyckades',
            code: 'REGISTRATION_FAILED',
          ),
        );
      }

      // Create user document in Firestore
      await _createUserDocument(user, params.role);

      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_handleFirebaseAuthError(e));
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett oväntat fel uppstod vid registrering',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> _validateEmailDomain(String email) async {
    try {
      // Remote Config already fetched in main.dart, just read the cached value
      final allowAllEmails = _remoteConfig.getBool('allow_all_emails_for_review');

      if (!allowAllEmails &&
          !email.endsWith('@algebraskolan.se') &&
          !email.endsWith('@algebrautbildning.se')) {
        return const Failure(
          ValidationError(
            message: 'Endast @algebraskolan.se eller @algebrautbildning.se är tillåtet',
            code: 'INVALID_DOMAIN',
          ),
        );
      }

      return const Success(null);
    } catch (e) {
      // If remote config fails, apply default domain restriction
      if (!email.endsWith('@algebraskolan.se') &&
          !email.endsWith('@algebrautbildning.se')) {
        return const Failure(
          ValidationError(
            message: 'Endast @algebraskolan.se eller @algebrautbildning.se är tillåtet',
            code: 'INVALID_DOMAIN',
          ),
        );
      }
      return const Success(null);
    }
  }

  Future<void> _createUserDocument(User user, String role) async {
    final displayName = user.email?.split('@')[0] ?? 'User';
    
    await _userRepository.createUserDocument(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      role: role == 'lärare' ? 'teacher' : 'student',
      classNumber: 0,
      coins: 0,
      hasAnsweredQuestionCorrectly: false,
    );
  }

  AppError _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const ValidationError(
          message: 'E-postadressen är redan registrerad',
          code: 'EMAIL_ALREADY_EXISTS',
        );
      case 'invalid-email':
        return const ValidationError(
          message: 'Ogiltig e-postadress',
          code: 'INVALID_EMAIL',
        );
      case 'weak-password':
        return const ValidationError(
          message: 'Lösenordet är för svagt',
          code: 'WEAK_PASSWORD',
        );
      case 'operation-not-allowed':
        return const AuthenticationError(
          message: 'E-post/lösenord-konton är inte aktiverade',
          code: 'OPERATION_NOT_ALLOWED',
        );
      default:
        return AuthenticationError(
          message: e.message ?? 'Registrering misslyckades',
          code: e.code,
          originalError: e,
        );
    }
  }
}