import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick utility to assign first 10 students to fritids groups for testing
Future<Map<String, dynamic>> quickAssignFritidsStudents() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Fetch first 20 students
    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(20)
        .get();

    if (studentsSnapshot.docs.isEmpty) {
      return {
        'success': false,
        'message': 'Inga elever hittades i databasen',
        'solenCount': 0,
        'havetCount': 0,
      };
    }

    int solenCount = 0;
    int havetCount = 0;

    // Assign alternating to Solen and Havet
    for (int i = 0; i < studentsSnapshot.docs.length; i++) {
      final studentDoc = studentsSnapshot.docs[i];
      final studentId = studentDoc.id;
      final studentName = studentDoc.data()['displayName'] ?? 'Unknown';

      // Alternate: even index = Solen, odd index = Havet
      final group = i % 2 == 0 ? 'solen' : 'havet';

      await firestore.collection('users').doc(studentId).update({
        'fritidsGroup': group,
      });

      if (group == 'solen') {
        solenCount++;
        print('✓ Assigned $studentName to Solen ☀️');
      } else {
        havetCount++;
        print('✓ Assigned $studentName to Havet 🌊');
      }
    }

    return {
      'success': true,
      'message': 'Tilldelning klar!',
      'solenCount': solenCount,
      'havetCount': havetCount,
      'total': solenCount + havetCount,
    };

  } catch (e) {
    return {
      'success': false,
      'message': 'Fel: $e',
      'solenCount': 0,
      'havetCount': 0,
    };
  }
}
