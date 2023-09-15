import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/coin_transaction.dart';
import '../page/student.dart';

class StudentProvider with ChangeNotifier {
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

  Future<void> fetchStudents(int classNumber) async {
    try {
      QuerySnapshot? snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('classNumber', isEqualTo: classNumber)
          .get();

      // Check for null or empty snapshot
      // ignore: unnecessary_null_comparison
      if (snapshot != null && snapshot.docs.isNotEmpty) {
        _students = snapshot.docs
            .map((doc) => ValueNotifier<Student>(Student.fromDocument(doc)))
            .toList();
      } else {
        // Optionally handle empty state, e.g., set _students to an empty list
        _students = [];
        print("No students found for class number: $classNumber");
      }
    } catch (error) {
      print("An error occurred while fetching students: $error");
      // Optionally set an error state in your model
      // e.g., _hasError = true;

      // Rethrow if you want to handle this error higher up in your application
      rethrow;
    } finally {
      // Notify listeners to rebuild widgets that depend on this data.
      // This is useful in both success and error cases.
      notifyListeners();
    }
  }

  Future<List<ValueNotifier<Student>>> fetchSearch(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      QuerySnapshot? snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayNameLower',
              isGreaterThanOrEqualTo: query.toLowerCase())
          .get();

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        List<ValueNotifier<Student>> searchResults = snapshot.docs
            .map((doc) => ValueNotifier<Student>(Student.fromDocument(doc)))
            .toList();
        return searchResults;
      } else {
        // Optionally handle empty state, e.g., return an empty list
        print("No results found for query: $query");
        return [];
      }
    } catch (error) {
      print("An error occurred while fetching search results: $error");
      // Rethrow if you want to handle this error higher up in your application
      rethrow;
    }
  }

  Future<bool> updateCoinsInDatabase(
      ValueNotifier<Student> studentNotifier) async {
    Student? currentStudent = studentNotifier.value;

    if (currentStudent == null || currentStudent.uid == null) {
      print('Student or student UID is null. Aborting updateCoinsInDatabase.');
      return false;
    }

    try {
      // Update the coins in the Firestore database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentStudent.uid)
          .update({
        'coins': FieldValue.increment(currentStudent.localCoins.value),
      });

      // Reset the local coins value
      currentStudent.localCoins.value = 0;

      notifyListeners();

      return true;
    } catch (e) {
      // Handle any errors here
      print('Error updating coins in Firestore: $e');
      return false;
    }
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
    if (student.value.localCoins.value > 0) {
      // Create a new transaction
      CoinTransaction transaction = CoinTransaction(
        teacherName: teacherName,
        amount: student.value.localCoins.value,
        timestamp: DateTime.now(),
      );

      // Convert the transaction to a map
      Map<String, dynamic> transactionMap = {
        'teacherName': transaction.teacherName,
        'amount': transaction.amount,
        'timestamp': transaction.timestamp,
        'isNew': true,
      };

      // Update the students' transaction history
      await FirebaseFirestore.instance
          .collection('students')
          .doc(student.value.uid)
          .collection('transactions')
          .add(transactionMap);

      // Update the coin count in the 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(student.value.uid)
          .update({
        'coins': FieldValue.increment(student.value.localCoins.value),
      });

      // Reset local coin count for the student
      student.value.localCoins.value = 0;
    }
  }

  Future<bool> updateAllCoins(String teacherName) async {
    bool hasErrorOccurred = false;

    for (var student in _students) {
      try {
        await updateStudentCoins(student, teacherName);
      } catch (e) {
        print(
            "An error occurred while updating coins for ${student.value.uid}: $e");
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
