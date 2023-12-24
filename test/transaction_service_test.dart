// logTransaction(String uid, int coins, String teacherName): Test that a new transaction is logged correctly with the given parameters.

import 'package:algebra/backend/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class OnNewTransactionMock extends Mock {
  void call(String message);
}

void main() {
  group('TransactionService', () {
    group('fetchAndUpdateTransactions', () {
      test('should fetch and update transactions correctly', () async {
        final FakeFirebaseFirestore fakeFirestore = FakeFirebaseFirestore();

        fakeFirestore
            .collection('students')
            .doc('student1')
            .collection('transactions')
            .doc('transaction1')
            .set({
          'teacherName': 'teacher1',
          'amount': 10,
          'timestamp': DateTime.now(),
          'isNew': true,
        });

        final TransactionService transactionService =
            TransactionService(firestore: fakeFirestore);

        await transactionService.fetchAndUpdateTransactions(
            'student1', OnNewTransactionMock());

        final DocumentSnapshot doc = await fakeFirestore
            .collection('students')
            .doc('student1')
            .collection('transactions')
            .doc('transaction1')
            .get();

        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        expect(data?['isNew'], false);
      });

      test('should call onNewTransaction with correct message', () async {
        final FakeFirebaseFirestore fakeFirestore = FakeFirebaseFirestore();

        fakeFirestore
            .collection('students')
            .doc('student1')
            .collection('transactions')
            .doc('transaction1')
            .set({
          'teacherName': 'teacher1',
          'amount': 10,
          'timestamp': DateTime.now(),
          'isNew': true,
        });

        final TransactionService transactionService =
            TransactionService(firestore: fakeFirestore);

        final OnNewTransactionMock onNewTransactionMock =
            OnNewTransactionMock();

        await transactionService.fetchAndUpdateTransactions(
            'student1', onNewTransactionMock);

        verify(() => onNewTransactionMock('teacher1 +10 algebronor.'))
            .called(1);
      });
    });

    group('logTransaction', () {
      test('should log transaction correctly', () async {
        final FakeFirebaseFirestore fakeFirestore = FakeFirebaseFirestore();

        final TransactionService transactionService =
            TransactionService(firestore: fakeFirestore);

        await transactionService.logTransaction('student1', 10, 'teacher1');

        final QuerySnapshot snapshot = await fakeFirestore
            .collection('students')
            .doc('student1')
            .collection('transactions')
            .get();

        expect((snapshot.docs[0].data() as Map<String, dynamic>)['teacherName'],
            'teacher1');
        expect((snapshot.docs[0].data() as Map<String, dynamic>)['amount'], 10);
      });
    });
  });
}
