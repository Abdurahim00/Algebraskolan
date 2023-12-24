import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/sound_manager.dart';
import '../backend/student_service.dart';
import '../backend/transaction_service.dart';
import '../backend/student.dart';

class StudentProvider with ChangeNotifier {
  final StudentService _studentService =
      StudentService(FirebaseFirestore.instance);

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
    notifyListeners(); // Notify listeners about the change
  }

// Fetch and sort all students by coins
  Future<List<ValueNotifier<Student>>> fetchAllStudentsSortedByCoins() async {
    try {
      List<Student> fetchedStudents = await _studentService.fetchAllStudents();
      fetchedStudents.sort((a, b) =>
          b.coins.compareTo(a.coins)); // Sort by coins in descending order
      return fetchedStudents
          .map((student) => ValueNotifier<Student>(student))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

//done
  Future<void> fetchStudents(int classNumber) async {
    try {
      List<Student> fetchedStudents =
          await _studentService.fetchStudentsByClassNumber(classNumber);
      _students = fetchedStudents
          .map((student) => ValueNotifier<Student>(student))
          .toList();
    } catch (error) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<List<ValueNotifier<Student>>> fetchAllStudents() async {
    try {
      List<Student> fetchedStudents = await _studentService.fetchAllStudents();
      return fetchedStudents
          .map((student) => ValueNotifier<Student>(student))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

//done
  Future<List<ValueNotifier<Student>>> fetchSearch(String query) async {
    try {
      List<Student> searchResults;
      if (query.isEmpty) {
        // Return all students if the query is empty
        searchResults = await _studentService.fetchAllStudents();
      } else {
        // Only search by name if there's a query
        searchResults =
            await _studentService.searchStudentsByDisplayName(query);
      }
      return searchResults
          .map((student) => ValueNotifier<Student>(student))
          .toList();
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

    bool updateSuccess = await _studentService.updateStudentCoinsInFirestore(
        currentStudent.uid, currentStudent.localCoins.value);

    if (updateSuccess) {
      // Reset the local coins value
      currentStudent.localCoins.value = 0;
      notifyListeners();
    }

    return updateSuccess;
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
      // Use the StudentService to handle the transaction
      await _studentService.updateCoinsWithTransaction(
          studentNotifier.value.uid, coinsToChange, teacherName);

      // Reset local coin count for the student
      studentNotifier.value.localCoins.value = 0;
      notifyListeners();
    } catch (e) {
      // Handle any exceptions, such as insufficient coins
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
      var updatedStudentUids = await _studentService
          .updateCoinsForMultipleStudents(studentCoinsUpdates);

      // Log transactions asynchronously
      logTransactionsInBackground(studentCoinsUpdates, teacherName);

      // Check if the coin update was successful
      if (updatedStudentUids.isEmpty) {
        failure = true;
        _isUpdatingCoins = false;
        notifyListeners();
        return false;
      }

      // Play success sound here
      await SoundManager.playSuccessSound();

      // Deselect all students after successful coin update
      handleDeselectAllStudents(); // Add this line
      _showCoinCalculator = false;
    }

    updated = true;
    _isUpdatingCoins = false;
    notifyListeners();
    return true;
  }

  Future<void> logTransactionsInBackground(
      Map<String, int> studentCoinsUpdates, String teacherName) async {
    for (var entry in studentCoinsUpdates.entries) {
      String uid = entry.key;
      int coins = entry.value;
      // Log transaction for each student without awaiting
      TransactionService().logTransaction(uid, coins, teacherName);
    }
  }

  void resetUpdated() {
    failure = false;
    updated = false;
    notifyListeners();
  }
}
