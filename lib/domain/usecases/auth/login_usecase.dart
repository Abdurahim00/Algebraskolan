import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_user_repository.dart';
import '../base_usecase.dart';

/// Parameters for login use case
class LoginParams extends Params {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  Map<String, dynamic> toMap() => {
    'email': email,
    'password': '***', // Don't log passwords
  };
}

/// Use case for user login with email and password
@lazySingleton
class LoginUseCase extends BaseUseCase<User, LoginParams> {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final FirebaseRemoteConfig _remoteConfig;

  LoginUseCase(
    this._authRepository,
    this._userRepository,
    this._remoteConfig,
  );

  @override
  Future<Result<User>> call(LoginParams params) async {
    try {
      // Validate email domain
      final domainValidation = await _validateEmailDomain(params.email);
      if (domainValidation.isFailure) {
        return Failure(domainValidation.errorOrNull!);
      }

      // Attempt login
      final user = await _authRepository.signInWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );

      if (user == null) {
        return const Failure(
          AuthenticationError(
            message: 'Fel e-postadress eller lösenord',
            code: 'INVALID_CREDENTIALS',
          ),
        );
      }

      // Check if user document exists
      final userDoc = await _userRepository.getUserDocument(user.uid);
      if (userDoc == null || !userDoc.exists) {
        // Create user document if it doesn't exist
        await _createDefaultUserDocument(user);
      }

      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_handleFirebaseAuthError(e));
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett oväntat fel uppstod vid inloggning',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> _validateEmailDomain(String email) async {
    try {
      await _remoteConfig.fetchAndActivate();
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

  Future<void> _createDefaultUserDocument(User user) async {
    final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
    
    await _userRepository.createUserDocument(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      role: 'student',
      classNumber: 0,
      coins: 0,
      hasAnsweredQuestionCorrectly: false,
    );
  }

  AppError _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return const AuthenticationError(
          message: 'Fel e-postadress eller lösenord',
          code: 'INVALID_CREDENTIALS',
        );
      case 'invalid-email':
        return const ValidationError(
          message: 'Ogiltig e-postadress',
          code: 'INVALID_EMAIL',
        );
      case 'user-disabled':
        return const AuthenticationError(
          message: 'Detta konto har inaktiverats',
          code: 'USER_DISABLED',
        );
      case 'too-many-requests':
        return const AuthenticationError(
          message: 'För många försök. Försök igen senare',
          code: 'TOO_MANY_REQUESTS',
        );
      default:
        return AuthenticationError(
          message: e.message ?? 'Inloggning misslyckades',
          code: e.code,
          originalError: e,
        );
    }
  }
}