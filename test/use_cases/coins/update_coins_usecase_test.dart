import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:algebra/domain/usecases/coins/update_coins_usecase.dart';
import 'package:algebra/domain/repositories/i_student_repository.dart';
import 'package:algebra/domain/repositories/i_transaction_repository.dart';
import 'package:algebra/domain/models/student_model.dart';
import 'package:algebra/core/result/result.dart';

import 'update_coins_usecase_test.mocks.dart';

@GenerateMocks([IStudentRepository, ITransactionRepository])
void main() {
  late UpdateCoinsUseCase updateCoinsUseCase;
  late MockIStudentRepository mockStudentRepository;
  late MockITransactionRepository mockTransactionRepository;

  setUp(() {
    mockStudentRepository = MockIStudentRepository();
    mockTransactionRepository = MockITransactionRepository();
    
    updateCoinsUseCase = UpdateCoinsUseCase(
      mockStudentRepository,
      mockTransactionRepository,
    );
  });

  group('UpdateCoinsUseCase', () {
    const testStudentId = 'student-123';
    const testTeacherName = 'Lärare Test';
    const testCoinAmount = 10;

    final testStudent = StudentModel(
      uid: testStudentId,
      email: 'student@algebraskolan.se',
      displayName: 'Test Student',
      displayNameLower: 'test student',
      role: 'student',
      classNumber: 5,
      coins: 50,
    );

    test('should return Success when coin update is successful', () async {
      // Arrange
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenAnswer((_) async => testStudent);
      when(mockStudentRepository.updateStudentCoins(
        uid: testStudentId,
        coinChange: testCoinAmount,
      )).thenAnswer((_) async => true);
      when(mockTransactionRepository.logTransaction(
        studentId: testStudentId,
        coins: testCoinAmount,
        teacherName: testTeacherName,
      )).thenAnswer((_) async => {});

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: testCoinAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.valueOrNull, true);
      verify(mockStudentRepository.updateStudentCoins(
        uid: testStudentId,
        coinChange: testCoinAmount,
      )).called(1);
      verify(mockTransactionRepository.logTransaction(
        studentId: testStudentId,
        coins: testCoinAmount,
        teacherName: testTeacherName,
      )).called(1);
    });

    test('should return ValidationError when coin amount is 0', () async {
      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: 0,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull?.code, 'INVALID_AMOUNT');
      verifyNever(mockStudentRepository.updateStudentCoins(
        uid: any,
        coinChange: any,
      ));
    });

    test('should return NotFoundError when student does not exist', () async {
      // Arrange
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenAnswer((_) async => null);

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: testCoinAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<NotFoundError>());
      expect(result.errorOrNull?.code, 'STUDENT_NOT_FOUND');
      verifyNever(mockStudentRepository.updateStudentCoins(
        uid: any,
        coinChange: any,
      ));
    });

    test('should return ValidationError when deduction exceeds balance', () async {
      // Arrange
      const negativeAmount = -60; // More than student's 50 coins
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenAnswer((_) async => testStudent);
      when(mockStudentRepository.fetchCurrentCoinBalance(testStudentId))
          .thenAnswer((_) async => 50);

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: negativeAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<ValidationError>());
      expect(result.errorOrNull?.code, 'INSUFFICIENT_BALANCE');
      verifyNever(mockStudentRepository.updateStudentCoins(
        uid: any,
        coinChange: any,
      ));
    });

    test('should allow deduction when balance is sufficient', () async {
      // Arrange
      const negativeAmount = -20; // Less than student's 50 coins
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenAnswer((_) async => testStudent);
      when(mockStudentRepository.fetchCurrentCoinBalance(testStudentId))
          .thenAnswer((_) async => 50);
      when(mockStudentRepository.updateStudentCoins(
        uid: testStudentId,
        coinChange: negativeAmount,
      )).thenAnswer((_) async => true);
      when(mockTransactionRepository.logTransaction(
        studentId: testStudentId,
        coins: negativeAmount,
        teacherName: testTeacherName,
      )).thenAnswer((_) async => {});

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: negativeAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isSuccess, true);
      verify(mockStudentRepository.updateStudentCoins(
        uid: testStudentId,
        coinChange: negativeAmount,
      )).called(1);
    });

    test('should return UnknownError when update fails', () async {
      // Arrange
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenAnswer((_) async => testStudent);
      when(mockStudentRepository.updateStudentCoins(
        uid: testStudentId,
        coinChange: testCoinAmount,
      )).thenAnswer((_) async => false);

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: testCoinAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<UnknownError>());
      expect(result.errorOrNull?.code, 'UPDATE_FAILED');
      verifyNever(mockTransactionRepository.logTransaction(
        studentId: any,
        coins: any,
        teacherName: any,
      ));
    });

    test('should handle unexpected exceptions', () async {
      // Arrange
      when(mockStudentRepository.getStudentById(testStudentId))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: testStudentId,
          coinAmount: testCoinAmount,
          teacherName: testTeacherName,
        ),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<UnknownError>());
      expect(result.errorOrNull?.message, contains('Ett fel uppstod vid uppdatering av mynt'));
    });
  });
}