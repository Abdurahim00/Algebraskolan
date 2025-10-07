import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/fritids_pass_registration_model.dart';
import '../../models/fritids_group.dart';
import '../../models/pass_type.dart';
import '../../repositories/i_fritids_repository.dart';
import '../base_usecase.dart';

/// Parameters for getting registrations by period
class GetRegistrationsByPeriodParams extends Params {
  final DateTime startDate;
  final DateTime endDate;
  final FritidsGroup? group;
  final PassType? passType;

  const GetRegistrationsByPeriodParams({
    required this.startDate,
    required this.endDate,
    this.group,
    this.passType,
  });

  @override
  Map<String, dynamic> toMap() => {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        if (group != null) 'group': group!.toValue(),
        if (passType != null) 'passType': passType!.toValue(),
      };
}

/// Use case for getting registrations within a time period
@lazySingleton
class GetRegistrationsByPeriodUseCase extends BaseUseCase<
    List<FritidsPassRegistrationModel>, GetRegistrationsByPeriodParams> {
  final IFritidsRepository _fritidsRepository;

  GetRegistrationsByPeriodUseCase(this._fritidsRepository);

  @override
  Future<Result<List<FritidsPassRegistrationModel>>> call(
      GetRegistrationsByPeriodParams params) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return const Failure(
          ValidationError(
            message: 'Slutdatum måste vara efter startdatum',
            code: 'INVALID_DATE_RANGE',
          ),
        );
      }

      // Get registrations for the period
      final registrations = await _getRegistrationsForPeriod(params);

      return Success(registrations);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid hämtning av registreringar',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<List<FritidsPassRegistrationModel>> _getRegistrationsForPeriod(
      GetRegistrationsByPeriodParams params) async {
    // Get all registrations for each day in the period
    final List<FritidsPassRegistrationModel> allRegistrations = [];

    DateTime currentDate = _normalizeDate(params.startDate);
    final endDate = _normalizeDate(params.endDate);

    while (!currentDate.isAfter(endDate)) {
      final dayRegistrations =
          await _fritidsRepository.getRegistrationsByDate(currentDate);

      // Filter by group and pass type if specified
      final filtered = dayRegistrations.where((reg) {
        if (params.group != null && reg.group != params.group) {
          return false;
        }
        if (params.passType != null && reg.passType != params.passType) {
          return false;
        }
        return true;
      }).toList();

      allRegistrations.addAll(filtered);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Sort by timestamp descending (newest first)
    allRegistrations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allRegistrations;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
