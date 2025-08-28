import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_student_repository.dart';
import '../../domain/models/student_model.dart';
import '../../core/cache/cache_manager.dart';

/// Firestore implementation of IStudentRepository with caching
@LazySingleton(as: IStudentRepository)
class CachedFirestoreStudentRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;
  final RepositoryCacheManager _cache;

  CachedFirestoreStudentRepository({
    FirebaseFirestore? firestore,
    RepositoryCacheManager? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? RepositoryCacheManager();

  @override
  Future<List<StudentModel>> fetchStudentsByClassNumber(int classNumber) async {
    final cacheKey = _cache.studentsKey(classNumber);
    
    return await _cache.getOrFetch(
      cacheKey,
      () async {
        final querySnapshot = await _firestore
            .collection('users')
            .where('classNumber', isEqualTo: classNumber)
            .where('role', isEqualTo: 'student')
            .get();

        return querySnapshot.docs
            .map((doc) => StudentModel.fromMap(
                  doc.data(),
                  id: doc.id,
                ))
            .toList();
      },
      decoder: (data) => (data as List)
          .map((e) => StudentModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      encoder: (students) => students.map((s) => s.toMap()).toList(),
    );
  }

  @override
  Future<List<StudentModel>> fetchAllStudents() async {
    const cacheKey = 'students_all';
    
    return await _cache.getOrFetch(
      cacheKey,
      () async {
        final querySnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .orderBy('displayNameLower')
            .get();

        return querySnapshot.docs
            .map((doc) => StudentModel.fromMap(
                  doc.data(),
                  id: doc.id,
                ))
            .toList();
      },
      decoder: (data) => (data as List)
          .map((e) => StudentModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      encoder: (students) => students.map((s) => s.toMap()).toList(),
    );
  }

  @override
  Future<StudentModel?> getStudentById(String uid) async {
    final cacheKey = _cache.studentKey(uid);
    
    return await _cache.getOrFetch(
      cacheKey,
      () async {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (!docSnapshot.exists) {
          return null;
        }

        return StudentModel.fromMap(
          docSnapshot.data()!,
          id: docSnapshot.id,
        );
      },
      decoder: (data) => data != null 
          ? StudentModel.fromMap(data as Map<String, dynamic>)
          : null,
      encoder: (student) => student?.toMap(),
    );
  }

  @override
  Future<List<StudentModel>> searchStudentsByDisplayName(String query) async {
    // Search queries are not cached as they are dynamic
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('displayNameLower')
        .startAt([query.toLowerCase()])
        .endAt(['${query.toLowerCase()}\uf8ff'])
        .get();

    return querySnapshot.docs
        .map((doc) => StudentModel.fromMap(
              doc.data(),
              id: doc.id,
            ))
        .toList();
  }

  @override
  Future<bool> updateStudentCoins({
    required String uid,
    required int coinChange,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'coins': FieldValue.increment(coinChange),
      });

      // Invalidate cache for this student
      await _cache.invalidateStudent(uid);
      
      return true;
    } catch (e) {
      print('Error updating student coins: $e');
      return false;
    }
  }

  @override
  Future<List<String>> updateCoinsForMultipleStudents(
    Map<String, int> studentCoinsUpdates,
  ) async {
    final batch = _firestore.batch();
    final updatedStudentIds = <String>[];

    for (var entry in studentCoinsUpdates.entries) {
      final uid = entry.key;
      final coinChange = entry.value;

      if (coinChange != 0) {
        final docRef = _firestore.collection('users').doc(uid);
        batch.update(docRef, {
          'coins': FieldValue.increment(coinChange),
        });
        updatedStudentIds.add(uid);
      }
    }

    try {
      await batch.commit();
      
      // Invalidate cache for all updated students
      for (final uid in updatedStudentIds) {
        await _cache.invalidateStudent(uid);
      }
      
      return updatedStudentIds;
    } catch (e) {
      print('Error in batch update: $e');
      return [];
    }
  }

  @override
  Future<void> deleteStudent(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      
      // Invalidate cache for this student
      await _cache.invalidateStudent(uid);
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  @override
  Future<int> fetchCurrentCoinBalance(String uid) async {
    final student = await getStudentById(uid);
    return student?.coins ?? 0;
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClass(int classNumber) {
    return _cache.streamWithCache(
      _cache.studentsKey(classNumber),
      _firestore
          .collection('users')
          .where('classNumber', isEqualTo: classNumber)
          .where('role', isEqualTo: 'student')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(
                    doc.data(),
                    id: doc.id,
                  ))
              .toList()),
      decoder: (data) => (data as List)
          .map((e) => StudentModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      encoder: (students) => students.map((s) => s.toMap()).toList(),
    );
  }

  @override
  Stream<StudentModel?> watchStudent(String uid) {
    return _cache.streamWithCache(
      _cache.studentKey(uid),
      _firestore
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return null;
        return StudentModel.fromMap(
          snapshot.data()!,
          id: snapshot.id,
        );
      }),
      decoder: (data) => data != null 
          ? StudentModel.fromMap(data as Map<String, dynamic>)
          : null,
      encoder: (student) => student?.toMap(),
    );
  }

  @override
  Future<void> updateStudentClass({
    required String uid,
    required int classNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'classNumber': classNumber,
      });

      // Invalidate cache for this student
      await _cache.invalidateStudent(uid);
    } catch (e) {
      print('Error updating student class: $e');
      rethrow;
    }
  }

  @override
  Future<void> markQuestionAnswered(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasAnsweredQuestionCorrectly': true,
      });

      // Invalidate cache for this student
      await _cache.invalidateStudent(uid);
    } catch (e) {
      print('Error marking question as answered: $e');
      rethrow;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cache.clear();
  }

  /// Dispose cache manager
  void dispose() {
    _cache.dispose();
  }
}