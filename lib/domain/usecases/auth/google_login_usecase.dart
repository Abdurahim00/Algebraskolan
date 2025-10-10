import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_user_repository.dart';
import '../base_usecase.dart';

/// Parameters for Google login
class GoogleLoginParams extends Params {
  final String accessToken;
  final String idToken;

  const GoogleLoginParams({
    required this.accessToken,
    required this.idToken,
  });

  @override
  Map<String, dynamic> toMap() => {
    'accessToken': accessToken,
    'idToken': idToken,
  };
}

/// Use case for Google sign in
@lazySingleton
class GoogleLoginUseCase extends BaseUseCase<User, GoogleLoginParams> {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final FirebaseRemoteConfig _remoteConfig;

  GoogleLoginUseCase(
    this._authRepository,
    this._userRepository,
    this._remoteConfig,
  );

  @override
  Future<Result<User>> call(GoogleLoginParams params) async {
    try {
      // Sign in with Google using the provided tokens
      final user = await (_authRepository as dynamic).signInWithGoogleTokens(
        accessToken: params.accessToken,
        idToken: params.idToken,
      );
      
      if (user == null) {
        return const Failure(
          AuthenticationError(
            message: 'Google-inloggning avbröts',
            code: 'GOOGLE_SIGNIN_CANCELLED',
          ),
        );
      }

      // Validate email domain
      final domainValidation = await _validateEmailDomain(user.email ?? '');
      if (domainValidation.isFailure) {
        // Sign out if domain is not allowed
        await _authRepository.signOut();
        return Failure(domainValidation.errorOrNull!);
      }

      // Check if user document exists
      final userDoc = await _userRepository.getUserDocument(user.uid);
      if (userDoc == null || !userDoc.exists) {
        // Create user document with default values
        await _createUserDocument(user);
      }

      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_handleFirebaseAuthError(e));
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett oväntat fel uppstod vid Google-inloggning',
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
          UnauthorizedError(
            message: 'Endast Algebraskolan-konton är tillåtna',
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
          UnauthorizedError(
            message: 'Endast Algebraskolan-konton är tillåtna',
            code: 'INVALID_DOMAIN',
          ),
        );
      }
      return const Success(null);
    }
  }

  Future<void> _createUserDocument(User user) async {
    final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
    final email = user.email ?? '';

    // Determine role based on email patterns
    String role = 'student';

    // Check for teacher patterns in email
    if (email.contains('listor') ||
        email.contains('teacher') ||
        email.contains('lärare') ||
        email.contains('pedagog')) {
      role = 'teacher';
    }

    await _userRepository.createUserDocument(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: role,
      classNumber: role == 'teacher' ? -1 : 0,
      coins: role == 'teacher' ? 9999 : 0,
      hasAnsweredQuestionCorrectly: false,
    );
  }

  AppError _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return const AuthenticationError(
          message: 'Ett konto finns redan med denna e-postadress',
          code: 'ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL',
        );
      case 'invalid-credential':
        return const AuthenticationError(
          message: 'Ogiltiga inloggningsuppgifter',
          code: 'INVALID_CREDENTIAL',
        );
      case 'operation-not-allowed':
        return const AuthenticationError(
          message: 'Google-inloggning är inte aktiverad',
          code: 'OPERATION_NOT_ALLOWED',
        );
      case 'user-disabled':
        return const AuthenticationError(
          message: 'Detta konto har inaktiverats',
          code: 'USER_DISABLED',
        );
      default:
        return AuthenticationError(
          message: e.message ?? 'Google-inloggning misslyckades',
          code: e.code,
          originalError: e,
        );
    }
  }
}