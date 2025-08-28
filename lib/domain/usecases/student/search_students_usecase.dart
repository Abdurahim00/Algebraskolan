import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/student_model.dart';
import '../../repositories/i_student_repository.dart';
import '../base_usecase.dart';

/// Parameters for searching students
class SearchStudentsParams extends Params {
  final String query;

  const SearchStudentsParams({required this.query});

  @override
  Map<String, dynamic> toMap() => {'query': query};
}

/// Use case for searching students
@lazySingleton
class SearchStudentsUseCase extends BaseUseCase<List<StudentModel>, SearchStudentsParams> {
  final IStudentRepository _studentRepository;

  SearchStudentsUseCase(this._studentRepository);

  @override
  Future<Result<List<StudentModel>>> call(SearchStudentsParams params) async {
    try {
      // Return empty list for empty query
      if (params.query.isEmpty) {
        return const Success([]);
      }

      // Search students by display name
      final students = await _studentRepository.searchStudentsByDisplayName(params.query);
      
      // Filter out non-students
      final filteredStudents = students.where((s) => s.role == 'student').toList();

      return Success(filteredStudents);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Sökning misslyckades',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}