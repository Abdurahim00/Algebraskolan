import '../core/di/injection_container.dart';
import '../core/result/result.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/student/fetch_students_usecase.dart';
import '../domain/usecases/coins/update_coins_usecase.dart';

/// Example demonstrating how to use the use cases with the DI container
class UseCaseExample {
  // Example 1: Using LoginUseCase
  Future<void> loginExample() async {
    // Get the use case from DI container
    final loginUseCase = InjectionContainer.loginUseCase;
    
    // Prepare parameters
    final params = LoginParams(
      email: 'teacher@algebraskolan.se',
      password: 'password123',
    );
    
    // Execute the use case
    final result = await loginUseCase(params);
    
    // Handle the result
    result.fold(
      onSuccess: (user) {
        print('Inloggning lyckades: ${user.displayName}');
        print('Roll: ${user.role}');
      },
      onFailure: (error) {
        print('Inloggning misslyckades: ${error.message}');
        if (error.code != null) {
          print('Felkod: ${error.code}');
        }
      },
    );
  }
  
  // Example 2: Using FetchStudentsUseCase
  Future<void> fetchStudentsExample() async {
    final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
    
    final params = FetchStudentsParams(
      classIds: ['class1', 'class2'],
      limit: 20,
    );
    
    final result = await fetchStudentsUseCase(params);
    
    result.fold(
      onSuccess: (students) {
        print('Hämtade ${students.length} studenter');
        for (final student in students) {
          print('- ${student.name}: ${student.coins} mynt');
        }
      },
      onFailure: (error) {
        print('Kunde inte hämta studenter: ${error.message}');
      },
    );
  }
  
  // Example 3: Using UpdateCoinsUseCase
  Future<void> updateCoinsExample() async {
    final updateCoinsUseCase = InjectionContainer.updateCoinsUseCase;
    
    final params = UpdateCoinsParams(
      studentId: 'student123',
      coinAmount: 10,
      teacherName: 'Lärarens Namn',
      description: 'Bra jobbat på provet!',
    );
    
    final result = await updateCoinsUseCase(params);
    
    result.fold(
      onSuccess: (_) {
        print('Mynt uppdaterade framgångsrikt');
      },
      onFailure: (error) {
        print('Kunde inte uppdatera mynt: ${error.message}');
        
        // Check specific error types
        if (error is ValidationError) {
          print('Valideringsfel: ${error.code}');
        } else if (error is NotFoundError) {
          print('Studenten hittades inte');
        }
      },
    );
  }
  
  // Example 4: Using BatchUpdateCoinsUseCase
  Future<void> batchUpdateExample() async {
    final batchUpdateUseCase = InjectionContainer.batchUpdateCoinsUseCase;
    
    final params = BatchUpdateCoinsParams(
      studentCoinsUpdates: {
        'student1': 5,
        'student2': 10,
        'student3': -2,  // Deduction
      },
      teacherName: 'Lärarens Namn',
    );
    
    final result = await batchUpdateUseCase(params);
    
    result.fold(
      onSuccess: (batchResult) {
        print('Batch-uppdatering klar');
        print('Lyckade: ${batchResult.successCount}');
        print('Misslyckade: ${batchResult.failureCount}');
        print('Totalt distribuerade mynt: ${batchResult.totalCoinsDistributed}');
        
        if (batchResult.hasFailures) {
          print('Misslyckade student-ID: ${batchResult.failedUpdates.join(', ')}');
        }
      },
      onFailure: (error) {
        print('Batch-uppdatering misslyckades: ${error.message}');
      },
    );
  }
  
  // Example 5: Chaining use cases
  Future<void> chainedUseCasesExample() async {
    // First login
    final loginUseCase = InjectionContainer.loginUseCase;
    final loginResult = await loginUseCase(
      LoginParams(
        email: 'teacher@algebraskolan.se',
        password: 'password123',
      ),
    );
    
    // If login successful, fetch students
    await loginResult.fold(
      onSuccess: (user) async {
        print('Inloggad som ${user.displayName}');
        
        // Now fetch students
        final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
        final studentsResult = await fetchStudentsUseCase(
          FetchStudentsParams(classIds: user.classIds ?? []),
        );
        
        await studentsResult.fold(
          onSuccess: (students) async {
            print('Hämtade ${students.length} studenter');
            
            // Update coins for all students
            final batchUpdateUseCase = InjectionContainer.batchUpdateCoinsUseCase;
            final updates = Map.fromEntries(
              students.map((s) => MapEntry(s.uid, 5)),
            );
            
            final updateResult = await batchUpdateUseCase(
              BatchUpdateCoinsParams(
                studentCoinsUpdates: updates,
                teacherName: user.displayName ?? 'Lärare',
              ),
            );
            
            updateResult.fold(
              onSuccess: (result) {
                print('Gav 5 mynt till ${result.successCount} studenter');
              },
              onFailure: (error) {
                print('Kunde inte uppdatera mynt: ${error.message}');
              },
            );
          },
          onFailure: (error) async {
            print('Kunde inte hämta studenter: ${error.message}');
          },
        );
      },
      onFailure: (error) async {
        print('Inloggning misslyckades: ${error.message}');
      },
    );
  }
}

// Usage in a widget or service
void main() async {
  // Make sure DI is initialized first
  // await setupServiceLocator();
  
  final example = UseCaseExample();
  
  // Run examples
  await example.loginExample();
  await example.fetchStudentsExample();
  await example.updateCoinsExample();
  await example.batchUpdateExample();
  await example.chainedUseCasesExample();
}