import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SeedDatabaseScreen extends StatefulWidget {
  const SeedDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<SeedDatabaseScreen> createState() => _SeedDatabaseScreenState();
}

class _SeedDatabaseScreenState extends State<SeedDatabaseScreen> {
  bool _isSeeding = false;
  String _status = 'Ready to seed database';
  List<String> _logs = [];

  // Swedish first names for test students
  final List<String> firstNames = [
    'Emma', 'Lucas', 'Maja', 'William', 'Elsa', 'Oscar', 'Alice', 'Noah',
    'Olivia', 'Liam', 'Astrid', 'Oliver', 'Ella', 'Hugo', 'Wilma', 'Leo',
    'Ebba', 'Adam', 'Alma', 'Matteo', 'Freja', 'Elias', 'Saga', 'Leon',
    'Agnes', 'Charlie', 'Selma', 'Alfred', 'Alba', 'Ludvig', 'Signe', 'Theo',
    'Stella', 'Harry', 'Isabella', 'Mohamed', 'Julia', 'Filip', 'Linnea', 'Vincent'
  ];

  // Swedish last names for test students
  final List<String> lastNames = [
    'Andersson', 'Johansson', 'Karlsson', 'Nilsson', 'Eriksson', 'Larsson',
    'Olsson', 'Persson', 'Svensson', 'Gustafsson', 'Pettersson', 'Jonsson',
    'Jansson', 'Hansson', 'Bengtsson', 'Jönsson', 'Lindberg', 'Jakobsson',
    'Magnusson', 'Lindström', 'Olofsson', 'Lindqvist', 'Lindgren', 'Berg',
    'Axelsson', 'Lundberg', 'Bergström', 'Lundgren', 'Mattsson', 'Berglund'
  ];

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      _status = message;
    });
  }

  Future<void> _createTeacherAccount() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    try {
      _addLog('🧑‍🏫 Creating teacher accounts...');

      final firestore = FirebaseFirestore.instance;

      // Create multiple teacher accounts for testing
      final teachers = [
        {
          'email': 'listor@algebrautbildning.se',
          'displayName': 'Teacher Listor',
          'uid': 'teacher_listor_dev',
        },
        {
          'email': 'teacher1@algebraskolan.se',
          'displayName': 'Teacher One',
          'uid': 'teacher_one_dev',
        },
        {
          'email': 'teacher2@algebrautbildning.se',
          'displayName': 'Teacher Two',
          'uid': 'teacher_two_dev',
        },
      ];

      for (var teacher in teachers) {
        final teacherData = {
          'uid': teacher['uid'],
          'email': teacher['email'],
          'displayName': teacher['displayName'],
          'displayNameLower': (teacher['displayName'] as String).toLowerCase(),
          'role': 'teacher',
          'classNumber': -1, // Teachers don't belong to a specific class
          'coins': 9999, // Teachers have unlimited coins for testing
          'hasAnsweredQuestionCorrectly': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add teacher to Firestore
        await firestore.collection('users').doc(teacher['uid'] as String).set(teacherData);
        _addLog('✅ Created: ${teacher['email']}');
      }

      _addLog('✅ All teacher accounts created successfully!');

    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting database seeding...');

      final firestore = FirebaseFirestore.instance;
      final random = Random();

      // Use a set to track used names to avoid duplicates
      Set<String> usedNames = {};
      int totalStudents = 0;

      // Classes 0 through 9
      for (int classNumber = 0; classNumber <= 9; classNumber++) {
        _addLog('📚 Creating students for Class $classNumber...');

        List<Map<String, dynamic>> classStudents = [];

        // Create 20 students per class
        for (int i = 0; i < 20; i++) {
          String displayName;

          // Generate unique name
          do {
            String firstName = firstNames[random.nextInt(firstNames.length)];
            String lastName = lastNames[random.nextInt(lastNames.length)];
            displayName = '$firstName $lastName';
          } while (usedNames.contains(displayName));

          usedNames.add(displayName);

          // Generate unique email
          String email = '${displayName.toLowerCase().replaceAll(' ', '.')}.class$classNumber@test.algebraskolan.se';

          // Generate UID (using format similar to Firebase Auth UIDs)
          String uid = 'test_student_${classNumber}_${i}_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}';

          // Random coins between 50 and 500
          int coins = 50 + random.nextInt(451);

          // Random chance if student has answered question correctly
          bool hasAnsweredQuestionCorrectly = random.nextDouble() < 0.7;

          // Create student document
          final studentData = {
            'uid': uid,
            'email': email,
            'displayName': displayName,
            'displayNameLower': displayName.toLowerCase(),
            'role': 'student',
            'classNumber': classNumber,
            'coins': coins,
            'hasAnsweredQuestionCorrectly': hasAnsweredQuestionCorrectly,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          classStudents.add(studentData);
          totalStudents++;
        }

        // Write students for this class in batch
        WriteBatch batch = firestore.batch();
        for (var studentData in classStudents) {
          final docRef = firestore.collection('users').doc(studentData['uid']);
          batch.set(docRef, studentData);
        }

        await batch.commit();
        _addLog('✅ Created ${classStudents.length} students for Class $classNumber');
      }

      _addLog('✨ Successfully created $totalStudents students!');

      // Verify the data
      _addLog('🔍 Verifying data...');

      int verifiedTotal = 0;
      for (int classNumber = 0; classNumber <= 9; classNumber++) {
        final querySnapshot = await firestore
            .collection('users')
            .where('classNumber', isEqualTo: classNumber)
            .where('role', isEqualTo: 'student')
            .get();

        verifiedTotal += querySnapshot.docs.length;
      }

      _addLog('📊 Total students in database: $verifiedTotal');
      _addLog('✅ Database seeding completed successfully!');

    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearDatabase() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    try {
      _addLog('🗑️ Clearing test students...');

      final firestore = FirebaseFirestore.instance;

      // Get all test students
      final querySnapshot = await firestore
          .collection('users')
          .where('uid', isGreaterThanOrEqualTo: 'test_student_')
          .where('uid', isLessThan: 'test_student_~')
          .get();

      _addLog('Found ${querySnapshot.docs.length} test students to delete');

      // Delete in batches
      WriteBatch batch = firestore.batch();
      int batchCount = 0;

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;

        // Firestore batch limit is 500
        if (batchCount == 500) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      _addLog('✅ Cleared ${querySnapshot.docs.length} test students');

    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Development Database'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Database Seeding Tool',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This will add 20 test students for each class (0-9) to the development database.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSeeding ? null : _seedDatabase,
                              icon: const Icon(Icons.add_circle),
                              label: const Text('Seed Students'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: _isSeeding ? null : _clearDatabase,
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Clear Test Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isSeeding ? null : _createTeacherAccount,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Create Teacher Accounts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _status.contains('❌') ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            if (_isSeeding)
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logs:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ..._logs.map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(log),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}