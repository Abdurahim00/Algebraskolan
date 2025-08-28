import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/models/coin_transaction_model.dart';

/// Firestore implementation of ITransactionRepository
@LazySingleton(as: ITransactionRepository)
class FirestoreTransactionRepository implements ITransactionRepository {
  final FirebaseFirestore _firestore;
  
  FirestoreTransactionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> addTransaction({
    required String studentId,
    required CoinTransactionModel transaction,
  }) async {
    try {
      final transactionMap = transaction.toMap();
      transactionMap['timestamp'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .add(transactionMap);
    } catch (e) {
      print('FirestoreTransactionRepository - addTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<List<CoinTransactionModel>> fetchAllTransactions(String studentId) async {
    if (studentId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CoinTransactionModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print('FirestoreTransactionRepository - fetchAllTransactions error: $e');
      return [];
    }
  }

  @override
  Future<CoinTransactionModel?> fetchLatestTransaction(String studentId) async {
    if (studentId.isEmpty) {
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return CoinTransactionModel.fromMap(
        snapshot.docs.first.data(), 
        id: snapshot.docs.first.id,
      );
    } catch (e) {
      print('FirestoreTransactionRepository - fetchLatestTransaction error: $e');
      return null;
    }
  }

  @override
  Future<List<CoinTransactionModel>> fetchTransactionsPaginated({
    required String studentId,
    required int limit,
    CoinTransactionModel? lastTransaction,
  }) async {
    if (studentId.isEmpty) {
      return [];
    }

    try {
      Query query = _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // If we have a last transaction, start after it
      if (lastTransaction != null && lastTransaction.id != null) {
        final lastDoc = await _firestore
            .collection('students')
            .doc(studentId)
            .collection('transactions')
            .doc(lastTransaction.id)
            .get();
        
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => CoinTransactionModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      print('FirestoreTransactionRepository - fetchTransactionsPaginated error: $e');
      return [];
    }
  }

  @override
  Future<void> logTransaction({
    required String studentId,
    required int coins,
    required String teacherName,
  }) async {
    if (studentId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .add({
        'teacherName': teacherName,
        'amount': coins,
        'timestamp': FieldValue.serverTimestamp(),
        'type': coins >= 0 ? 'earn' : 'spend',
      });
    } catch (e) {
      print('FirestoreTransactionRepository - logTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<void> batchLogTransactions({
    required Map<String, int> studentCoinsUpdates,
    required String teacherName,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var entry in studentCoinsUpdates.entries) {
        final studentId = entry.key;
        final coins = entry.value;
        
        final docRef = _firestore
            .collection('students')
            .doc(studentId)
            .collection('transactions')
            .doc(); // Generate a new document ID
        
        batch.set(docRef, {
          'teacherName': teacherName,
          'amount': coins,
          'timestamp': FieldValue.serverTimestamp(),
          'type': coins >= 0 ? 'earn' : 'spend',
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('FirestoreTransactionRepository - batchLogTransactions error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<CoinTransactionModel>> watchTransactions(String studentId) {
    if (studentId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoinTransactionModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<void> deleteAllTransactions(String studentId) async {
    try {
      final batch = _firestore.batch();
      
      final snapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('All transactions deleted for student: $studentId');
    } catch (e) {
      print('FirestoreTransactionRepository - deleteAllTransactions error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionStats(String studentId) async {
    if (studentId.isEmpty) {
      return {
        'totalEarned': 0,
        'totalSpent': 0,
        'netBalance': 0,
        'transactionCount': 0,
      };
    }

    try {
      final transactions = await fetchAllTransactions(studentId);
      
      int totalEarned = 0;
      int totalSpent = 0;
      
      for (final transaction in transactions) {
        if (transaction.amount > 0) {
          totalEarned += transaction.amount;
        } else {
          totalSpent += transaction.amount.abs();
        }
      }
      
      return {
        'totalEarned': totalEarned,
        'totalSpent': totalSpent,
        'netBalance': totalEarned - totalSpent,
        'transactionCount': transactions.length,
        'averageTransaction': transactions.isNotEmpty 
            ? (totalEarned - totalSpent) / transactions.length 
            : 0,
      };
    } catch (e) {
      print('FirestoreTransactionRepository - getTransactionStats error: $e');
      return {
        'totalEarned': 0,
        'totalSpent': 0,
        'netBalance': 0,
        'transactionCount': 0,
      };
    }
  }
}