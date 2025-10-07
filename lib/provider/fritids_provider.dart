import 'package:flutter/material.dart';
import '../backend/student.dart';
import '../core/di/injection_container.dart';
import '../domain/models/fritids_group.dart';
import '../domain/models/pass_type.dart';
import '../domain/models/fritids_pass_registration_model.dart';
import '../domain/models/student_model.dart';
import '../domain/usecases/student/fetch_students_usecase.dart';
import '../domain/usecases/fritids/register_fritids_pass_usecase.dart';
import '../domain/usecases/fritids/get_today_fritids_registrations_usecase.dart';

class FritidsProvider with ChangeNotifier {
  FritidsGroup? _selectedGroup;
  PassType _selectedPassType = PassType.fm;
  List<StudentModel> _students = [];
  List<FritidsPassRegistrationModel> _todayRegistrations = [];
  List<StudentModel> _selectedStudents = [];
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _errorMessage;
  bool _registrationSuccess = false;

  // Getters
  FritidsGroup? get selectedGroup => _selectedGroup;
  PassType get selectedPassType => _selectedPassType;
  List<StudentModel> get students => [..._students];
  List<StudentModel> get selectedStudents => [..._selectedStudents];
  List<FritidsPassRegistrationModel> get todayRegistrations => [..._todayRegistrations];
  bool get isLoading => _isLoading;
  bool get isRegistering => _isRegistering;
  String? get errorMessage => _errorMessage;
  bool get registrationSuccess => _registrationSuccess;

  // Check if a student has registered for the current selected pass type today
  bool hasRegisteredForCurrentPass(String studentId) {
    if (_selectedGroup == null) return false;

    return _todayRegistrations.any((reg) =>
        reg.studentId == studentId &&
        reg.group == _selectedGroup &&
        reg.passType == _selectedPassType &&
        !reg.isReverted);
  }

  // Check if a student has registered for FM today
  bool hasRegisteredForFM(String studentId) {
    if (_selectedGroup == null) return false;

    return _todayRegistrations.any((reg) =>
        reg.studentId == studentId &&
        reg.group == _selectedGroup &&
        reg.passType == PassType.fm &&
        !reg.isReverted);
  }

  // Check if a student has registered for EM today
  bool hasRegisteredForEM(String studentId) {
    if (_selectedGroup == null) return false;

    return _todayRegistrations.any((reg) =>
        reg.studentId == studentId &&
        reg.group == _selectedGroup &&
        reg.passType == PassType.em &&
        !reg.isReverted);
  }

  // Convert domain model to legacy Student model for compatibility
  Student _domainToLegacyStudent(StudentModel domainStudent) {
    return Student(
      uid: domainStudent.uid,
      displayName: domainStudent.displayName,
      classNumber: domainStudent.classNumber,
      role: domainStudent.role,
      coins: domainStudent.coins,
      hasAnsweredQuestionCorrectly: domainStudent.hasAnsweredQuestionCorrectly,
      transactions: [],
    );
  }

  // Set selected group and load students
  Future<void> selectGroup(FritidsGroup group) async {
    if (_selectedGroup == group) return;

    _selectedGroup = group;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([
      _fetchGroupStudents(),
      _fetchTodayRegistrations(),
    ]);
  }

  // Toggle pass type between FM and EM
  void selectPassType(PassType passType) {
    if (_selectedPassType == passType) return;

    _selectedPassType = passType;
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch students belonging to the selected group
  Future<void> _fetchGroupStudents() async {
    if (_selectedGroup == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
      final result = await fetchStudentsUseCase(
        const FetchStudentsParams(),
      );

      result.fold(
        onSuccess: (allStudents) {
          // Filter students by fritids group
          _students = allStudents
              .where((student) =>
                  student.role == 'student' &&
                  student.fritidsGroup == _selectedGroup)
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
        },
        onFailure: (error) {
          _errorMessage = 'Kunde inte hämta elever: ${error.message}';
          _students = [];
        },
      );
    } catch (e) {
      _errorMessage = 'Ett oväntat fel uppstod: $e';
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch today's registrations for the selected group
  Future<void> _fetchTodayRegistrations() async {
    if (_selectedGroup == null) return;

    try {
      final useCase = InjectionContainer.getTodayFritidsRegistrationsUseCase;
      final result = await useCase(
        GetTodayFritidsRegistrationsParams(
          group: _selectedGroup,
        ),
      );

      result.fold(
        onSuccess: (registrations) {
          _todayRegistrations = registrations;
        },
        onFailure: (error) {
          print('Error fetching today\'s registrations: ${error.message}');
          _todayRegistrations = [];
        },
      );
    } catch (e) {
      print('Unexpected error fetching registrations: $e');
      _todayRegistrations = [];
    }

    notifyListeners();
  }

  // Register a pass for a student
  Future<bool> registerPass(String studentId, String studentName) async {
    if (_selectedGroup == null) {
      _errorMessage = 'Ingen grupp vald';
      notifyListeners();
      return false;
    }

    // Check if already registered
    if (hasRegisteredForCurrentPass(studentId)) {
      _errorMessage = 'Eleven har redan registrerats för detta pass idag';
      notifyListeners();
      return false;
    }

    _isRegistering = true;
    _errorMessage = null;
    _registrationSuccess = false;
    notifyListeners();

    try {
      final registerUseCase = InjectionContainer.registerFritidsPassUseCase;
      final result = await registerUseCase(
        RegisterFritidsPassParams(
          studentId: studentId,
          studentName: studentName,
          group: _selectedGroup!,
          passType: _selectedPassType,
        ),
      );

      return result.fold(
        onSuccess: (registrationId) async {
          // Refresh today's registrations to update UI
          await _fetchTodayRegistrations();
          _registrationSuccess = true;
          notifyListeners();

          // Reset success flag after a delay
          Future.delayed(const Duration(seconds: 2), () {
            _registrationSuccess = false;
            notifyListeners();
          });

          return true;
        },
        onFailure: (error) {
          _errorMessage = error.message;
          return false;
        },
      );
    } catch (e) {
      _errorMessage = 'Ett oväntat fel uppstod: $e';
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Refresh both students and registrations
  Future<void> refresh() async {
    if (_selectedGroup == null) return;

    await Future.wait([
      _fetchGroupStudents(),
      _fetchTodayRegistrations(),
    ]);
  }

  // Toggle student selection
  void toggleStudentSelection(StudentModel student) {
    if (_selectedStudents.contains(student)) {
      _selectedStudents.remove(student);
    } else {
      // Only allow selection if not already registered for current pass
      if (!hasRegisteredForCurrentPass(student.uid)) {
        _selectedStudents.add(student);
      }
    }
    notifyListeners();
  }

  // Select all students
  void selectAllStudents() {
    _selectedStudents = _students
        .where((student) => !hasRegisteredForCurrentPass(student.uid))
        .toList();
    notifyListeners();
  }

  // Deselect all students
  void deselectAllStudents() {
    _selectedStudents.clear();
    notifyListeners();
  }

  // Batch register selected students
  Future<bool> registerSelectedStudents() async {
    if (_selectedStudents.isEmpty) {
      _errorMessage = 'Inga elever valda';
      notifyListeners();
      return false;
    }

    if (_selectedGroup == null) {
      _errorMessage = 'Ingen grupp vald';
      notifyListeners();
      return false;
    }

    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    int successCount = 0;
    int failCount = 0;

    try {
      // Register all students in parallel for better performance
      final registerUseCase = InjectionContainer.registerFritidsPassUseCase;
      final results = await Future.wait(
        _selectedStudents.map((student) => registerUseCase(
          RegisterFritidsPassParams(
            studentId: student.uid,
            studentName: student.displayName,
            group: _selectedGroup!,
            passType: _selectedPassType,
          ),
        )),
      );

      // Count successes and failures
      for (final result in results) {
        result.fold(
          onSuccess: (_) => successCount++,
          onFailure: (_) => failCount++,
        );
      }

      // Refresh registrations
      await _fetchTodayRegistrations();

      // Clear selection
      _selectedStudents.clear();

      // Show success
      _registrationSuccess = true;
      notifyListeners();

      // Reset success flag
      Future.delayed(const Duration(seconds: 2), () {
        _registrationSuccess = false;
        notifyListeners();
      });

      return failCount == 0;
    } catch (e) {
      _errorMessage = 'Ett oväntat fel uppstod: $e';
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Reset error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
