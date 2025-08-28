import '../models/student_model.dart';
import '../models/coin_transaction_model.dart';

/// Interface for student repository
/// Defines all student-related data operations
abstract class IStudentRepository {
  /// Fetch students by class number
  Future<List<StudentModel>> fetchStudentsByClassNumber(int classNumber);
  
  /// Fetch all students
  Future<List<StudentModel>> fetchAllStudents();
  
  /// Search students by display name
  Future<List<StudentModel>> searchStudentsByDisplayName(String query);
  
  /// Get student by ID
  Future<StudentModel?> getStudentById(String uid);
  
  /// Update student coins
  Future<bool> updateStudentCoins({
    required String uid,
    required int coinChange,
  });
  
  /// Batch update coins for multiple students
  Future<List<String>> updateCoinsForMultipleStudents(
    Map<String, int> studentCoinsUpdates,
  );
  
  /// Get current coin balance for a student
  Future<int> fetchCurrentCoinBalance(String uid);
  
  /// Update student data
  Future<bool> updateStudent(StudentModel student);
  
  /// Delete student document
  Future<void> deleteStudentDocument(String uid);
  
  /// Create or update student document
  Future<void> createOrUpdateStudent(StudentModel student);
  
  /// Stream of student updates
  Stream<StudentModel?> watchStudent(String uid);
  
  /// Stream of students by class
  Stream<List<StudentModel>> watchStudentsByClass(int classNumber);
}