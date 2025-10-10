import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/fritids_group.dart';

/// Utility to create fake test students for fritids testing
/// These are clearly marked as test data and won't interfere with real students
Future<Map<String, dynamic>> createFakeStudentsForFritids() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Create fake students with clear test naming
    final fakeStudents = [
      // Solen group students
      {
        'uid': 'test_student_solen_1',
        'email': 'test.solen1@fake.com',
        'displayName': 'Test Solen 1',
        'displayNameLower': 'test solen 1',
        'role': 'student',
        'classNumber': 99, // Use class 99 to avoid conflicts with real classes
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'solen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true, // Mark as test data
      },
      {
        'uid': 'test_student_solen_2',
        'email': 'test.solen2@fake.com',
        'displayName': 'Test Solen 2',
        'displayNameLower': 'test solen 2',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'solen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_solen_3',
        'email': 'test.solen3@fake.com',
        'displayName': 'Test Solen 3',
        'displayNameLower': 'test solen 3',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'solen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_solen_4',
        'email': 'test.solen4@fake.com',
        'displayName': 'Test Solen 4',
        'displayNameLower': 'test solen 4',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'solen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_solen_5',
        'email': 'test.solen5@fake.com',
        'displayName': 'Test Solen 5',
        'displayNameLower': 'test solen 5',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'solen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      // Havet group students
      {
        'uid': 'test_student_havet_1',
        'email': 'test.havet1@fake.com',
        'displayName': 'Test Havet 1',
        'displayNameLower': 'test havet 1',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'havet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_havet_2',
        'email': 'test.havet2@fake.com',
        'displayName': 'Test Havet 2',
        'displayNameLower': 'test havet 2',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'havet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_havet_3',
        'email': 'test.havet3@fake.com',
        'displayName': 'Test Havet 3',
        'displayNameLower': 'test havet 3',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'havet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_havet_4',
        'email': 'test.havet4@fake.com',
        'displayName': 'Test Havet 4',
        'displayNameLower': 'test havet 4',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'havet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
      {
        'uid': 'test_student_havet_5',
        'email': 'test.havet5@fake.com',
        'displayName': 'Test Havet 5',
        'displayNameLower': 'test havet 5',
        'role': 'student',
        'classNumber': 99,
        'coins': 0,
        'hasAnsweredQuestionCorrectly': false,
        'fritidsGroup': 'havet',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestStudent': true,
      },
    ];

    // Check if test students already exist
    final existingTestStudents = await firestore
        .collection('users')
        .where('isTestStudent', isEqualTo: true)
        .get();

    if (existingTestStudents.docs.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Test students already exist! Delete them first if you want to recreate.',
        'count': existingTestStudents.docs.length,
      };
    }

    // Create all fake students
    WriteBatch batch = firestore.batch();
    int solenCount = 0;
    int havetCount = 0;

    for (final student in fakeStudents) {
      final docRef =
          firestore.collection('users').doc(student['uid'] as String);
      batch.set(docRef, student);

      if (student['fritidsGroup'] == 'solen') {
        solenCount++;
        print('✓ Created fake student: ${student['displayName']} → Solen ☀️');
      } else {
        havetCount++;
        print('✓ Created fake student: ${student['displayName']} → Havet 🌊');
      }
    }

    await batch.commit();

    return {
      'success': true,
      'message': 'Fake students created successfully!',
      'solenCount': solenCount,
      'havetCount': havetCount,
      'total': solenCount + havetCount,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Error creating fake students: $e',
      'solenCount': 0,
      'havetCount': 0,
    };
  }
}

/// Utility to delete all fake test students
Future<Map<String, dynamic>> deleteFakeStudents() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Find all test students
    final testStudentsSnapshot = await firestore
        .collection('users')
        .where('isTestStudent', isEqualTo: true)
        .get();

    if (testStudentsSnapshot.docs.isEmpty) {
      return {
        'success': false,
        'message': 'No test students found to delete',
        'deletedCount': 0,
      };
    }

    // Delete all test students
    WriteBatch batch = firestore.batch();
    for (final doc in testStudentsSnapshot.docs) {
      batch.delete(doc.reference);
      print('✓ Deleting fake student: ${doc.data()['displayName']}');
    }

    await batch.commit();

    return {
      'success': true,
      'message': 'All fake students deleted successfully!',
      'deletedCount': testStudentsSnapshot.docs.length,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Error deleting fake students: $e',
      'deletedCount': 0,
    };
  }
}
