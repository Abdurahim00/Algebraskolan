import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/student_model.dart';
import '../../repositories/i_student_repository.dart';
import '../base_usecase.dart';

/// Parameters for fetching students
class FetchStudentsParams extends Params {
  final int? classNumber;
  final bool sortByCoins;

  const FetchStudentsParams({
    this.classNumber,
    this.sortByCoins = false,
  });

  @override
  Map<String, dynamic> toMap() => {
    'classNumber': classNumber,
    'sortByCoins': sortByCoins,
  };
}

/// Use case for fetching students
@lazySingleton
class FetchStudentsUseCase extends BaseUseCase<List<StudentModel>, FetchStudentsParams> {
  final IStudentRepository _studentRepository;

  FetchStudentsUseCase(this._studentRepository);

  @override
  Future<Result<List<StudentModel>>> call(FetchStudentsParams params) async {
    try {
      List<StudentModel> students;
      
      // Fetch students based on parameters
      if (params.classNumber != null) {
        students = await _studentRepository.fetchStudentsByClassNumber(params.classNumber!);
      } else {
        students = await _studentRepository.fetchAllStudents();
      }

      // Filter out non-students (teachers, etc.)
      students = students.where((s) => s.role == 'student').toList();

      // Sort by coins if requested
      if (params.sortByCoins) {
        students.sort((a, b) => b.coins.compareTo(a.coins));
      }

      return Success(students);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Kunde inte hämta studenter',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}