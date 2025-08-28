import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:algebra/domain/usecases/auth/login_usecase.dart';
import 'package:algebra/domain/repositories/i_auth_repository.dart';
import 'package:algebra/domain/repositories/i_user_repository.dart';
import 'package:algebra/core/result/result.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([IAuthRepository, IUserRepository, FirebaseRemoteConfig, User])
void main() {
  late LoginUseCase loginUseCase;
  late MockIAuthRepository mockAuthRepository;
  late MockIUserRepository mockUserRepository;
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepository = MockIAuthRepository();
    mockUserRepository = MockIUserRepository();
    mockRemoteConfig = MockFirebaseRemoteConfig();
    mockUser = MockUser();
    
    loginUseCase = LoginUseCase(
      mockAuthRepository,
      mockUserRepository,
      mockRemoteConfig,
    );
  });

  group('LoginUseCase', () {
    const testEmail = 'test@algebraskolan.se';
    const testPassword = 'password123';
    const testUid = 'test-uid-123';

    test('should return Success when login is successful with valid domain', () async {
      // Arrange
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      when(mockRemoteConfig.getBool('allow_all_emails_for_review')).thenReturn(false);
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUser);
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(testEmail);
      when(mockUserRepository.getUserDocument(testUid))
          .thenAnswer((_) async => null); // Simulate existing user

      // Act
      final result = await loginUseCase(
        LoginParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.valueOrNull, mockUser);
      verify(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    test('should return ValidationError when email domain is invalid', () async {
      // Arrange
      const invalidEmail = 'test@gmail.com';
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      when(mockRemoteConfig.getBool('allow_all_emails_for_review')).thenReturn(false);

      // Act
      final result = await loginUseCase(
        LoginParams(email: invalidEmail, password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull?.code, 'INVALID_DOMAIN');
      verifyNever(mockAuthRepository.signInWithEmailAndPassword(
        email: any,
        password: any,
      ));
    });

    test('should return ValidationError when email is empty', () async {
      // Act
      final result = await loginUseCase(
        LoginParams(email: '', password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull?.code, 'MISSING_EMAIL');
    });

    test('should return ValidationError when password is empty', () async {
      // Act
      final result = await loginUseCase(
        LoginParams(email: testEmail, password: ''),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull?.code, 'MISSING_PASSWORD');
    });

    test('should return AuthenticationError when credentials are wrong', () async {
      // Arrange
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      when(mockRemoteConfig.getBool('allow_all_emails_for_review')).thenReturn(false);
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      // Act
      final result = await loginUseCase(
        LoginParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<AuthenticationError>());
      expect(result.errorOrNull?.code, 'WRONG_PASSWORD');
    });

    test('should create user document if it does not exist', () async {
      // Arrange
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      when(mockRemoteConfig.getBool('allow_all_emails_for_review')).thenReturn(false);
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUser);
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(testEmail);
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUserRepository.getUserDocument(testUid))
          .thenAnswer((_) async => null);

      // Act
      final result = await loginUseCase(
        LoginParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result.isSuccess, true);
      verify(mockUserRepository.createUserDocument(
        uid: testUid,
        email: testEmail,
        displayName: 'Test User',
        role: 'student',
        classNumber: 0,
        coins: 0,
        hasAnsweredQuestionCorrectly: false,
      )).called(1);
    });

    test('should allow all emails when remote config flag is true', () async {
      // Arrange
      const anyEmail = 'test@gmail.com';
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      when(mockRemoteConfig.getBool('allow_all_emails_for_review')).thenReturn(true);
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: anyEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUser);
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(anyEmail);
      when(mockUserRepository.getUserDocument(testUid))
          .thenAnswer((_) async => null);

      // Act
      final result = await loginUseCase(
        LoginParams(email: anyEmail, password: testPassword),
      );

      // Assert
      expect(result.isSuccess, true);
      verify(mockAuthRepository.signInWithEmailAndPassword(
        email: anyEmail,
        password: testPassword,
      )).called(1);
    });
  });
}