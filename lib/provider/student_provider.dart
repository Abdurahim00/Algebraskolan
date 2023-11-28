import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/coin_transaction.dart';
import '../backend/student_service.dart';
import '../page/student.dart';

class StudentProvider with ChangeNotifier {
  final StudentService _studentService =
      StudentService(FirebaseFirestore.instance);
  List<ValueNotifier<Student>> _students = [];
  int selectedClass = 0;
  final Set<ValueNotifier<Student>> _selectedStudents = {};
  bool _showButton = false;
  bool updated = false;
  bool failure = false;

  Set<ValueNotifier<Student>> get selectedStudents => {..._selectedStudents};
  List<ValueNotifier<Student>> get students => [..._students];
  bool get showButton => _showButton;

  void setShowButton(bool value) {
    _showButton = value;
    notifyListeners();
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

//done
  Future<List<ValueNotifier<Student>>> fetchSearch(String query) async {
    try {
      List<Student> searchResults =
          await _studentService.searchStudentsByDisplayName(query);
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
      ValueNotifier<Student> student, String teacherName) async {
    // Create a new transaction
    CoinTransaction transaction = CoinTransaction(
      teacherName: teacherName,
      amount: student.value.localCoins.value,
      timestamp: DateTime.now(),
    );

    // Use the StudentService to add the transaction and update coins
    await _studentService.addTransactionToStudent(
        student.value.uid, transaction);
    await _studentService.updateStudentCoinsInFirestore(
        student.value.uid, student.value.localCoins.value);

    // Reset local coin count for the student
    student.value.localCoins.value = 0;
  }

  Future<bool> updateAllCoins(String teacherName) async {
    bool hasErrorOccurred = false;

    for (var student in _students) {
      try {
        await updateStudentCoins(student, teacherName);
      } catch (e) {
        hasErrorOccurred = true;
      }
    }

    if (hasErrorOccurred) {
      failure = true;
      notifyListeners();
      return false;
    } else {
      updated = true;
      notifyListeners();
      return true;
    }
  }

  void resetUpdated() {
    failure = false;
    updated = false;
    notifyListeners();
  }
}
