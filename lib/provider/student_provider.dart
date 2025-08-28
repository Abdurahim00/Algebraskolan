import 'package:algebra/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../backend/control_page.dart';
import '../backend/sound_manager.dart';
import '../backend/student.dart';
import '../core/di/injection_container.dart';
import '../core/result/result.dart';
import '../domain/models/student_model.dart';
import '../domain/usecases/student/fetch_students_usecase.dart';
import '../domain/usecases/student/search_students_usecase.dart';
import '../domain/usecases/coins/update_coins_usecase.dart';
import '../domain/usecases/coins/batch_update_coins_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';

class StudentProvider with ChangeNotifier {
  List<ValueNotifier<Student>> _students = [];
  int selectedClass = 0;
  final Set<ValueNotifier<Student>> _selectedStudents = {};
  bool _showButton = false;
  bool updated = false;
  bool failure = false;
  bool _isUpdatingCoins = false;

  Set<ValueNotifier<Student>> get selectedStudents => {..._selectedStudents};
  List<ValueNotifier<Student>> get students => [..._students];
  bool get showButton => _showButton;
  bool get isUpdatingCoins => _isUpdatingCoins;

  bool _showCoinCalculator = false;
  bool get showCoinCalculator => _showCoinCalculator;

  StudentProvider();

  void setShowCoinCalculator(bool value) {
    _showCoinCalculator = value;
    notifyListeners();
  }

  void setShowButton(bool value) {
    _showButton = value;
    notifyListeners();
  }

  void setIsUpdatingCoins(bool value) {
    _isUpdatingCoins = value;
    notifyListeners();
  }

  // Convert domain model to legacy Student model
  Student _domainToLegacyStudent(StudentModel domainStudent) {
    return Student(
      uid: domainStudent.uid,
      displayName: domainStudent.displayName,
      classNumber: domainStudent.classNumber,
      role: domainStudent.role,
      coins: domainStudent.coins,
      hasAnsweredQuestionCorrectly: domainStudent.hasAnsweredQuestionCorrectly,
      transactions: [], // Empty transactions list
    );
  }

  // Fetch and sort all students by coins, excluding teachers
  Future<List<ValueNotifier<Student>>> fetchAllStudentsSortedByCoins() async {
    try {
      final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
      final result = await fetchStudentsUseCase(
        const FetchStudentsParams(),
      );
      
      return result.fold(
        onSuccess: (students) {
          // Sort by coins in descending order and filter students only
          final sorted = students
              .where((student) => student.role == 'student')
              .toList()
            ..sort((a, b) => b.coins.compareTo(a.coins));
          
          return sorted
              .map((student) => ValueNotifier<Student>(_domainToLegacyStudent(student)))
              .toList();
        },
        onFailure: (error) {
          print('Error fetching students sorted by coins: ${error.message}');
          throw Exception(error.message);
        },
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchStudents(int classNumber) async {
    try {
      final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
      final result = await fetchStudentsUseCase(
        FetchStudentsParams(
          classNumber: classNumber,
        ),
      );
      
      result.fold(
        onSuccess: (fetchedStudents) {
          _students = fetchedStudents
              .where((student) => student.role == 'student')
              .map((student) => ValueNotifier<Student>(_domainToLegacyStudent(student)))
              .toList();
        },
        onFailure: (error) {
          print('Error fetching students: ${error.message}');
          throw Exception(error.message);
        },
      );
    } catch (error) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<List<ValueNotifier<Student>>> fetchAllStudents() async {
    try {
      final fetchStudentsUseCase = InjectionContainer.fetchStudentsUseCase;
      final result = await fetchStudentsUseCase(
        const FetchStudentsParams(),
      );
      
      return result.fold(
        onSuccess: (students) {
          return students
              .where((student) => student.role == 'student')
              .map((student) => ValueNotifier<Student>(_domainToLegacyStudent(student)))
              .toList();
        },
        onFailure: (error) {
          print('Error fetching all students: ${error.message}');
          throw Exception(error.message);
        },
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<List<ValueNotifier<Student>>> fetchSearch(String query) async {
    try {
      if (query.isEmpty) {
        // Return all students if the query is empty
        return await fetchAllStudents();
      }
      
      final searchStudentsUseCase = InjectionContainer.searchStudentsUseCase;
      final result = await searchStudentsUseCase(
        SearchStudentsParams(
          query: query,
        ),
      );
      
      return result.fold(
        onSuccess: (students) {
          return students
              .where((student) => student.role == 'student')
              .map((student) => ValueNotifier<Student>(_domainToLegacyStudent(student)))
              .toList();
        },
        onFailure: (error) {
          print('Error searching students: ${error.message}');
          throw Exception(error.message);
        },
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> updateCoinsInDatabase(
      ValueNotifier<Student> studentNotifier) async {
    Student? currentStudent = studentNotifier.value;

    // ignore: unnecessary_null_comparison
    if (currentStudent == null || currentStudent.uid == null) {
      return false;
    }

    final updateCoinsUseCase = InjectionContainer.updateCoinsUseCase;
    final currentUser = InjectionContainer.authRepository.currentUser;
    final teacherName = currentUser?.displayName ?? 'Lärare';
    
    final result = await updateCoinsUseCase(
      UpdateCoinsParams(
        studentId: currentStudent.uid,
        coinAmount: currentStudent.localCoins.value,
        teacherName: teacherName,
      ),
    );

    return result.fold(
      onSuccess: (_) {
        // Reset the local coins value
        currentStudent.localCoins.value = 0;
        notifyListeners();
        return true;
      },
      onFailure: (error) {
        print('Error updating coins: ${error.message}');
        return false;
      },
    );
  }

  void addSelectedStudent(ValueNotifier<Student> student) {
    selectedStudents.add(student);
    notifyListeners();
  }

  void removeSelectedStudent(ValueNotifier<Student> student) {
    selectedStudents.remove(student);
    notifyListeners();
  }

  void toggleStudentSelection(ValueNotifier<Student> student) {
    if (selectedStudents.contains(student)) {
      removeSelectedStudent(student);
    } else {
      addSelectedStudent(student);
    }
  }

  void toggleSelection(ValueNotifier<Student> studentNotifier) {
    if (_selectedStudents.contains(studentNotifier)) {
      handleDeselectStudent(studentNotifier);
    } else {
      handleSelectStudent(studentNotifier);
    }
    // Update the visibility of the coin calculator based on selection
    setShowCoinCalculator(_selectedStudents.isNotEmpty);
  }

  void incrementCoins(ValueNotifier<Student> studentNotifier) {
    Student currentStudent = studentNotifier.value;
    currentStudent.localCoins.value += 1;

    notifyListeners();
    bool shouldShowButton =
        students.any((student) => student.value.localCoins.value > 0);
    setShowButton(shouldShowButton);
  }

  void decrementCoins(ValueNotifier<Student> studentNotifier) {
    Student currentStudent = studentNotifier.value;
    if (currentStudent.localCoins.value > 0) {
      currentStudent.localCoins.value -= 1;
    }

    notifyListeners();
    bool shouldShowButton =
        students.any((student) => student.value.localCoins.value > 0);
    setShowButton(shouldShowButton);
  }

  void incrementAllSelected() {
    for (ValueNotifier<Student> studentNotifier in _selectedStudents) {
      incrementCoins(studentNotifier);
    }
  }

  void decrementAllSelected() {
    for (ValueNotifier<Student> studentNotifier in _selectedStudents) {
      decrementCoins(studentNotifier);
    }
  }

  void clearStudents() {
    _students.clear();
    notifyListeners();
  }

  void handleClassChanged(int newClass) async {
    if (selectedClass != newClass) {
      selectedClass = newClass;
      _selectedStudents.clear();
      setShowCoinCalculator(false);
      await fetchStudents(newClass);
      setShowButton(false);
      notifyListeners();
    }
  }

  void handleSelectStudent(ValueNotifier<Student> studentNotifier) {
    _selectedStudents.add(studentNotifier);
    notifyListeners();
  }

  void handleDeselectStudent(ValueNotifier<Student> studentNotifier) {
    _selectedStudents.remove(studentNotifier);
    notifyListeners();
  }

  void handleDeselectAllStudents() {
    _selectedStudents.clear();
    notifyListeners();
  }

  void handleSelectAllStudents() {
    _selectedStudents.addAll(_students);
    notifyListeners();
  }

  Future<void> updateStudentCoins(
      ValueNotifier<Student> studentNotifier, String teacherName) async {
    int coinsToChange = studentNotifier.value.localCoins.value;

    try {
      final updateCoinsUseCase = InjectionContainer.updateCoinsUseCase;
      final result = await updateCoinsUseCase(
        UpdateCoinsParams(
          studentId: studentNotifier.value.uid,
          coinAmount: coinsToChange,
          teacherName: teacherName,
        ),
      );

      result.fold(
        onSuccess: (_) {
          // Reset local coin count for the student
          studentNotifier.value.localCoins.value = 0;
          notifyListeners();
        },
        onFailure: (error) {
          debugPrint('Error updating coins: ${error.message}');
          throw Exception(error.message);
        },
      );
    } catch (e) {
      debugPrint('Error updating coins: $e');
      rethrow;
    }
  }

  Future<bool> updateAllCoins(String teacherName) async {
    _isUpdatingCoins = true;
    notifyListeners();

    Map<String, int> studentCoinsUpdates = {};
    for (var student in _students) {
      if (student.value.localCoins.value > 0) {
        studentCoinsUpdates[student.value.uid] = student.value.localCoins.value;
        student.value.localCoins.value = 0; // Reset local coin count
      }
    }

    if (studentCoinsUpdates.isNotEmpty) {
      final batchUpdateUseCase = InjectionContainer.batchUpdateCoinsUseCase;
      final result = await batchUpdateUseCase(
        BatchUpdateCoinsParams(
          studentCoinsUpdates: studentCoinsUpdates,
          teacherName: teacherName,
        ),
      );

      return result.fold(
        onSuccess: (batchResult) async {
          if (batchResult.allSuccessful) {
            // Play success sound here
            await SoundManager.playSuccessSound();

            // Deselect all students after successful coin update
            handleDeselectAllStudents();
            _showCoinCalculator = false;

            updated = true;
            _isUpdatingCoins = false;
            notifyListeners();
            return true;
          } else {
            print('Some updates failed: ${batchResult.failedUpdates.join(', ')}');
            failure = true;
            _isUpdatingCoins = false;
            notifyListeners();
            return false;
          }
        },
        onFailure: (error) {
          print('Batch update failed: ${error.message}');
          failure = true;
          _isUpdatingCoins = false;
          notifyListeners();
          return false;
        },
      );
    }

    _isUpdatingCoins = false;
    notifyListeners();
    return true;
  }

  void resetUpdated() {
    failure = false;
    updated = false;
    notifyListeners();
  }

  Future<void> deleteUserAccount(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // First, delete the user's document from Firestore
        final userRepository = InjectionContainer.userRepository;
        await userRepository.deleteUserData(user.uid);

        // Disconnect from third-party providers if necessary
        if (user.providerData.any((p) => p.providerId == 'google.com')) {
          // Disconnect from Google
          final googleSignIn = GoogleSignIn();
          await googleSignIn.disconnect();
        }

        // Then delete the user from Authentication
        await user.delete();
        print("User account deleted successfully.");

        // Sign out using LogoutUseCase
        final logoutUseCase = InjectionContainer.logoutUseCase;
        await logoutUseCase();

        // Navigate to login page or somewhere else as needed
        navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.message}");
      // Handle Firebase Auth errors
    } catch (e) {
      print("Error during the deletion process: ${e}");
      // Handle other errors
    }
  }
}