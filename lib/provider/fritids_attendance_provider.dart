import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/di/injection_container.dart';
import '../domain/models/pass_type.dart';

class FritidsAttendanceProvider with ChangeNotifier {
  List<Map<String, dynamic>>? _attendanceData;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>>? get attendanceData => _attendanceData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAttendance(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = 'Ingen användare inloggad';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch all students
      final studentRepository = InjectionContainer.studentRepository;
      final students = await studentRepository.fetchAllStudents();

      // Fetch registrations for the selected date
      final fritidsRepository = InjectionContainer.fritidsRepository;
      final registrations =
          await fritidsRepository.getRegistrationsByDate(date);

      if (students.isNotEmpty) {
        // Filter non-reverted registrations
        final activeRegistrations =
            registrations.where((r) => !r.isReverted).toList();

        // Build attendance data
        final attendanceList = <Map<String, dynamic>>[];

        for (var student in students) {
          // Check if student has FM pass
          final hasFM = activeRegistrations.any(
              (r) => r.studentId == student.uid && r.passType == PassType.fm);

          // Check if student has EM pass
          final hasEM = activeRegistrations.any(
              (r) => r.studentId == student.uid && r.passType == PassType.em);

          attendanceList.add({
            'id': student.uid,
            'name': student.displayName,
            'classNum': student.classNumber,
            'hasFM': hasFM,
            'hasEM': hasEM,
            'fritidsGroup': student.fritidsGroup,
          });
        }

        // Sort by class and name
        attendanceList.sort((a, b) {
          final classCompare =
              (a['classNum'] as int).compareTo(b['classNum'] as int);
          if (classCompare != 0) return classCompare;
          return (a['name'] as String).compareTo(b['name'] as String);
        });

        _attendanceData = attendanceList;
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Inga elever hittades';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Ett oväntat fel uppstod: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
