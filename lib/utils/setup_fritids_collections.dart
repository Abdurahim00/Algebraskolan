import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to test and initialize Firestore collections for fritids
/// This will help diagnose if there are collection/indexing issues
Future<Map<String, dynamic>> setupFritidsCollections() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔧 Setting up fritids collections...');

    // Test 1: Check if we can write to fritidsPassRegistrations collection
    print('📝 Testing fritidsPassRegistrations collection...');
    final testRegistration = {
      'studentId': 'test_setup_student',
      'studentName': 'Test Setup Student',
      'group': 'solen',
      'passType': 'fm',
      'date': DateTime.now().millisecondsSinceEpoch,
      'timestamp': FieldValue.serverTimestamp(),
      'staffId': 'test_staff',
      'staffName': 'Test Staff',
      'algebronaAwarded': 1,
      'isReverted': false,
      'isTestDocument': true, // Mark as test document
    };

    final registrationRef = await firestore
        .collection('fritidsPassRegistrations')
        .add(testRegistration);

    print('✅ Successfully created test registration: ${registrationRef.id}');

    // Test 2: Check if we can read from the collection
    print('📖 Testing read from fritidsPassRegistrations...');
    final readSnapshot = await firestore
        .collection('fritidsPassRegistrations')
        .where('isTestDocument', isEqualTo: true)
        .get();

    print('✅ Successfully read ${readSnapshot.docs.length} test registrations');

    // Test 3: Check if we can write to batchTransactions collection
    print('📝 Testing batchTransactions collection...');
    final testBatchTransaction = {
      'teacherId': 'test_teacher',
      'timestamp': FieldValue.serverTimestamp(),
      'isReverted': false,
      'studentTransactions': [
        {
          'studentId': 'test_student_1',
          'coins': 5,
          'teacherName': 'Test Teacher',
        }
      ],
      'isTestDocument': true, // Mark as test document
    };

    final batchRef = await firestore
        .collection('batchTransactions')
        .add(testBatchTransaction);

    print('✅ Successfully created test batch transaction: ${batchRef.id}');

    // Test 4: Check if we can read from batchTransactions
    print('📖 Testing read from batchTransactions...');
    final batchSnapshot = await firestore
        .collection('batchTransactions')
        .where('isTestDocument', isEqualTo: true)
        .get();

    print(
        '✅ Successfully read ${batchSnapshot.docs.length} test batch transactions');

    // Test 5: Check if users collection supports fritidsGroup field
    print('👥 Testing users collection fritidsGroup field...');
    final testUser = {
      'uid': 'test_fritids_user',
      'email': 'test.fritids@setup.com',
      'displayName': 'Test Fritids User',
      'displayNameLower': 'test fritids user',
      'role': 'student',
      'classNumber': 99,
      'coins': 0,
      'hasAnsweredQuestionCorrectly': false,
      'fritidsGroup': 'solen',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTestDocument': true,
    };

    await firestore.collection('users').doc('test_fritids_user').set(testUser);

    print('✅ Successfully created test user with fritidsGroup');

    return {
      'success': true,
      'message': 'All fritids collections are working correctly!',
      'collections': [
        'fritidsPassRegistrations ✅',
        'batchTransactions ✅',
        'users (with fritidsGroup) ✅',
      ],
    };
  } catch (e, stackTrace) {
    print('❌ Error setting up collections: $e');
    print('Stack trace: $stackTrace');

    return {
      'success': false,
      'message': 'Error setting up collections: $e',
      'collections': [],
    };
  }
}

/// Clean up test documents
Future<Map<String, dynamic>> cleanupTestDocuments() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🧹 Cleaning up test documents...');

    // Delete test registrations
    final registrationSnapshot = await firestore
        .collection('fritidsPassRegistrations')
        .where('isTestDocument', isEqualTo: true)
        .get();

    WriteBatch batch = firestore.batch();
    for (final doc in registrationSnapshot.docs) {
      batch.delete(doc.reference);
      print('🗑️ Deleting test registration: ${doc.id}');
    }

    // Delete test batch transactions
    final batchSnapshot = await firestore
        .collection('batchTransactions')
        .where('isTestDocument', isEqualTo: true)
        .get();

    for (final doc in batchSnapshot.docs) {
      batch.delete(doc.reference);
      print('🗑️ Deleting test batch transaction: ${doc.id}');
    }

    // Delete test user
    final userDoc = firestore.collection('users').doc('test_fritids_user');
    final userExists = await userDoc.get();
    if (userExists.exists) {
      batch.delete(userDoc);
      print('🗑️ Deleting test user: test_fritids_user');
    }

    await batch.commit();

    return {
      'success': true,
      'message': 'Test documents cleaned up successfully!',
      'deletedCount': registrationSnapshot.docs.length +
          batchSnapshot.docs.length +
          (userExists.exists ? 1 : 0),
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Error cleaning up: $e',
      'deletedCount': 0,
    };
  }
}
