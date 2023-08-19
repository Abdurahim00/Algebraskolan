import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../page/student.dart';

class StudentProvider with ChangeNotifier {
  List<ValueNotifier<Student>> _students = [];
  int selectedClass = 0;
  final Set<ValueNotifier<Student>> _selectedStudents = {};
  bool _showButton = false;
  bool updated = false;

  Set<ValueNotifier<Student>> get selectedStudents => {..._selectedStudents};
  List<ValueNotifier<Student>> get students => [..._students];
  bool get showButton => _showButton;

  void setShowButton(bool value) {
    _showButton = value;
    notifyListeners();
  }

  Future<void> fetchStudents(int classNumber) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('classNumber', isEqualTo: classNumber)
          .get();

      _students = snapshot.docs
          .map((doc) => ValueNotifier<Student>(Student.fromDocument(doc)))
          .toList();

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<ValueNotifier<Student>>> fetchSearch(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayNameLower',
              isGreaterThanOrEqualTo: query.toLowerCase())
          .get();

      List<ValueNotifier<Student>> searchResults = snapshot.docs
          .map((doc) => ValueNotifier<Student>(Student.fromDocument(doc)))
          .toList();

      return searchResults;
    } catch (error) {
      rethrow;
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

  void updateAllCoins() {
    for (var student in _students) {
      if (student.value.localCoins.value > 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(student.value.uid)
            .update({
          'coins': FieldValue.increment(student.value.localCoins.value),
        });
        updated = true;
        student.value.localCoins.value = 0;
      }
    }
    setShowButton(false);
    notifyListeners();
  }

  void resetUpdated() {
    updated = false;
    notifyListeners();
  }
}
