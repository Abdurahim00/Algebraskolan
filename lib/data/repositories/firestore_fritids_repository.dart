import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_fritids_repository.dart';
import '../../domain/models/fritids_pass_registration_model.dart';
import '../../domain/models/fritids_group.dart';
import '../../domain/models/pass_type.dart';

/// Firestore implementation of IFritidsRepository
@LazySingleton(as: IFritidsRepository)
class FirestoreFritidsRepository implements IFritidsRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'fritidsPassRegistrations';

  FirestoreFritidsRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Normalize date to start of day for consistent querying
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Future<String> registerPass(FritidsPassRegistrationModel registration) async {
    try {
      print('FirestoreFritidsRepository: Registering pass for ${registration.studentName}');

      // Check if already registered
      final alreadyRegistered = await hasRegisteredToday(
        registration.studentId,
        registration.group,
        registration.passType,
        registration.date,
      );

      if (alreadyRegistered) {
        throw Exception('Student already registered for this pass today');
      }

      final docRef = await _firestore
          .collection(_collectionName)
          .add(registration.toMap());

      print('FirestoreFritidsRepository: Pass registered with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('FirestoreFritidsRepository - registerPass error: $e');
      rethrow;
    }
  }

  @override
  Future<List<FritidsPassRegistrationModel>> getRegistrationsByDate(DateTime date) async {
    try {
      final normalizedDate = _normalizeDate(date);
      print('FirestoreFritidsRepository: Querying registrations for date: $normalizedDate (${normalizedDate.millisecondsSinceEpoch})');

      // Query without orderBy to avoid needing composite index while it's building
      // We'll sort in memory instead
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('date', isEqualTo: normalizedDate.millisecondsSinceEpoch)
          .where('isReverted', isEqualTo: false)
          .get();

      print('FirestoreFritidsRepository: Found ${snapshot.docs.length} registrations for $normalizedDate');

      // Convert to models and sort by timestamp in memory
      final registrations = snapshot.docs
          .map((doc) => FritidsPassRegistrationModel.fromMap(doc.data(), id: doc.id))
          .toList();

      // Sort by timestamp descending (newest first)
      registrations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return registrations;
    } catch (e) {
      print('FirestoreFritidsRepository - getRegistrationsByDate error: $e');
      return [];
    }
  }

  @override
  Future<List<FritidsPassRegistrationModel>> getTodayRegistrationsByGroup(
      FritidsGroup group) async {
    try {
      final today = _normalizeDate(DateTime.now());
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('date', isEqualTo: today.millisecondsSinceEpoch)
          .where('group', isEqualTo: group.toValue())
          .where('isReverted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FritidsPassRegistrationModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print('FirestoreFritidsRepository - getTodayRegistrationsByGroup error: $e');
      return [];
    }
  }

  @override
  Future<List<FritidsPassRegistrationModel>> getTodayRegistrationsByGroupAndPass(
    FritidsGroup group,
    PassType passType,
  ) async {
    try {
      final today = _normalizeDate(DateTime.now());
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('date', isEqualTo: today.millisecondsSinceEpoch)
          .where('group', isEqualTo: group.toValue())
          .where('passType', isEqualTo: passType.toValue())
          .where('isReverted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FritidsPassRegistrationModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print('FirestoreFritidsRepository - getTodayRegistrationsByGroupAndPass error: $e');
      return [];
    }
  }

  @override
  Future<bool> hasRegisteredToday(
    String studentId,
    FritidsGroup group,
    PassType passType,
    DateTime date,
  ) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('studentId', isEqualTo: studentId)
          .where('group', isEqualTo: group.toValue())
          .where('passType', isEqualTo: passType.toValue())
          .where('date', isEqualTo: normalizedDate.millisecondsSinceEpoch)
          .where('isReverted', isEqualTo: false)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('FirestoreFritidsRepository - hasRegisteredToday error: $e');
      return false;
    }
  }

  @override
  Future<List<FritidsPassRegistrationModel>> getStudentRegistrations(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('studentId', isEqualTo: studentId)
          .where('isReverted', isEqualTo: false);

      if (startDate != null) {
        final normalizedStart = _normalizeDate(startDate);
        query = query.where('date',
            isGreaterThanOrEqualTo: normalizedStart.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        final normalizedEnd = _normalizeDate(endDate);
        query = query.where('date',
            isLessThanOrEqualTo: normalizedEnd.millisecondsSinceEpoch);
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => FritidsPassRegistrationModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      print('FirestoreFritidsRepository - getStudentRegistrations error: $e');
      return [];
    }
  }

  @override
  Future<bool> revertRegistration(String registrationId, String staffId) async {
    try {
      print('FirestoreFritidsRepository: Reverting registration $registrationId');

      final docRef = _firestore.collection(_collectionName).doc(registrationId);
      final doc = await docRef.get();

      if (!doc.exists) {
        print('FirestoreFritidsRepository: Registration not found');
        return false;
      }

      final registration = FritidsPassRegistrationModel.fromMap(
        doc.data()!,
        id: doc.id,
      );

      if (registration.isReverted) {
        print('FirestoreFritidsRepository: Registration already reverted');
        return false;
      }

      await docRef.update({
        'isReverted': true,
        'revertedBy': staffId,
        'revertedAt': FieldValue.serverTimestamp(),
      });

      print('FirestoreFritidsRepository: Registration reverted successfully');
      return true;
    } catch (e) {
      print('FirestoreFritidsRepository - revertRegistration error: $e');
      return false;
    }
  }

  @override
  Future<FritidsPassRegistrationModel?> getRegistrationById(String registrationId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(registrationId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return FritidsPassRegistrationModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      print('FirestoreFritidsRepository - getRegistrationById error: $e');
      return null;
    }
  }

  @override
  Future<FritidsPassRegistrationModel?> getLastRegistrationByStaff(String staffId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('staffId', isEqualTo: staffId)
          .where('isReverted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FritidsPassRegistrationModel.fromMap(
        snapshot.docs.first.data(),
        id: snapshot.docs.first.id,
      );
    } catch (e) {
      print('FirestoreFritidsRepository - getLastRegistrationByStaff error: $e');
      return null;
    }
  }
}
