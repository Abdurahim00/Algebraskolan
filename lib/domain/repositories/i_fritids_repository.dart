import '../models/fritids_pass_registration_model.dart';
import '../models/fritids_group.dart';
import '../models/pass_type.dart';

/// Repository interface for Fritids pass registrations
abstract class IFritidsRepository {
  /// Register a pass for a student
  /// Returns the registration ID if successful
  Future<String> registerPass(FritidsPassRegistrationModel registration);

  /// Get all registrations for a specific date
  Future<List<FritidsPassRegistrationModel>> getRegistrationsByDate(DateTime date);

  /// Get today's registrations for a specific group
  Future<List<FritidsPassRegistrationModel>> getTodayRegistrationsByGroup(FritidsGroup group);

  /// Get today's registrations for a specific group and pass type
  Future<List<FritidsPassRegistrationModel>> getTodayRegistrationsByGroupAndPass(
    FritidsGroup group,
    PassType passType,
  );

  /// Check if a student has already registered for a specific pass today
  Future<bool> hasRegisteredToday(
    String studentId,
    FritidsGroup group,
    PassType passType,
    DateTime date,
  );

  /// Get all registrations for a specific student
  Future<List<FritidsPassRegistrationModel>> getStudentRegistrations(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Revert a pass registration
  Future<bool> revertRegistration(String registrationId, String staffId);

  /// Get a specific registration by ID
  Future<FritidsPassRegistrationModel?> getRegistrationById(String registrationId);

  /// Get the last registration for a specific staff member
  /// (for undo functionality)
  Future<FritidsPassRegistrationModel?> getLastRegistrationByStaff(String staffId);
}
