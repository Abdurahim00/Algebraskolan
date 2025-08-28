import 'package:flutter_test/flutter_test.dart';
import 'package:algebra/core/di/service_locator.dart';
import 'package:algebra/domain/repositories/i_auth_repository.dart';
import 'package:algebra/domain/repositories/i_student_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import '../test/firebase_mock.dart';

void main() {
  setUpAll(() async {
    // Setup Firebase for testing
    setupFirebaseAuthMocks();
    await Firebase.initializeApp();
  });

  group('Dependency Injection Tests', () {
    test('Service locator should initialize without errors', () async {
      await setupServiceLocator();
      
      // Check if repositories are registered
      expect(isRegistered<IAuthRepository>(), true);
      expect(isRegistered<IStudentRepository>(), true);
    });

    test('Should be able to retrieve repositories', () async {
      await resetServiceLocator();
      await setupServiceLocator();
      
      final authRepo = sl<IAuthRepository>();
      final studentRepo = sl<IStudentRepository>();
      
      expect(authRepo, isNotNull);
      expect(studentRepo, isNotNull);
    });
  });
}

// Mock setup for Firebase
void setupFirebaseAuthMocks() {
  // This would be implemented with proper Firebase test mocks
  // For now, this is a placeholder
}