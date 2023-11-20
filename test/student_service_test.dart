import 'package:algebra/backend/coin_transaction.dart';
import 'package:algebra/backend/student_service.dart';
import 'package:algebra/page/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentService', () {
    group('fetchStudentsByClassNumber', () {
      test('returns a list of students for an existent class number', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore.collection('users').add({
          'classNumber': 1,
          'displayName': 'John Doe',
          'displayNameLower': 'john doe',
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
          'role': 'student',
        });

        final StudentService studentService = StudentService(firestore);

        final students = await studentService.fetchStudentsByClassNumber(1);

        expect(students, isA<List<Student>>());
      });

      test('returns an empty list for a non-existent class number', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final StudentService studentService = StudentService(firestore);

        final students = await studentService.fetchStudentsByClassNumber(1);

        expect(students, []);
      });
    });

    group('searchStudentsByDisplayName', () {
      test('returns a list of students for a matching case insensitive query',
          () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore.collection('users').add({
          'classNumber': 1,
          'displayName': 'John Doe',
          'displayNameLower': 'john doe',
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
          'role': 'student',
        });

        final StudentService studentService = StudentService(firestore);

        final students =
            await studentService.searchStudentsByDisplayName('John Doe');

        expect(students, isA<List<Student>>());
      });

      test('returns a list of students for a matching case sensitive query',
          () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore.collection('users').add({
          'classNumber': 1,
          'displayName': 'John Doe',
          'displayNameLower': 'john doe',
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
          'role': 'student',
        });

        final StudentService studentService = StudentService(firestore);

        final students =
            await studentService.searchStudentsByDisplayName('john doe');

        expect(students, isA<List<Student>>());
      });

      test('returns an empty list for a non-matching query', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final StudentService studentService = StudentService(firestore);

        final students =
            await studentService.searchStudentsByDisplayName('John Doe');

        expect(students, []);
      });
    });

    group('updateStudentCoinsInFirestore', () {
      test('updates the student coins in Firestore with positive increment',
          () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final StudentService studentService = StudentService(firestore);

        await firestore.collection('users').doc('uid').set({
          'classNumber': 1,
          'displayName': 'John Doe',
          'displayNameLower': 'john doe',
          'coins': 0,
          'hasAnsweredQuestionCorrectly': false,
          'role': 'student',
        });

        await studentService.updateStudentCoinsInFirestore('uid', 10);

        final snapshot = await firestore.collection('users').get();

        expect(snapshot.docs.first.data()['coins'], 10);
      });

      test('updates the student coins in Firestore with negative increment',
          () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final StudentService studentService = StudentService(firestore);

        await firestore.collection('users').doc('uid').set({
          'classNumber': 1,
          'displayName': 'John Doe',
          'displayNameLower': 'john doe',
          'coins': 10,
          'hasAnsweredQuestionCorrectly': false,
          'role': 'student',
        });

        await studentService.updateStudentCoinsInFirestore('uid', -10);

        final snapshot = await firestore.collection('users').get();

        expect(snapshot.docs.first.data()['coins'], 0);
      });
    });

    group('addTransactionToStudent', () {
      test('adds a transaction to the student in Firestore', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final StudentService studentService = StudentService(firestore);

        final dateTimeNow = DateTime.now();

        await studentService.addTransactionToStudent(
            'uid',
            CoinTransaction(
                teacherName: 'teacherName',
                amount: 10,
                timestamp: dateTimeNow));

        final student = await firestore
            .collection('students')
            .doc('uid')
            .collection('transactions')
            .get();

        expect(student.docs.first.data(), {
          'teacherName': 'teacherName',
          'amount': 10,
          'timestamp': Timestamp.fromDate(dateTimeNow),
          'isNew': true,
        });
      });
    });
  });
}
