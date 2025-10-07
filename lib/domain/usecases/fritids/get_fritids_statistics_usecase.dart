import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/fritids_pass_registration_model.dart';
import '../../models/fritids_group.dart';
import '../../models/pass_type.dart';
import '../../repositories/i_fritids_repository.dart';
import '../base_usecase.dart';

/// Parameters for getting fritids statistics
class GetFritidsStatisticsParams extends Params {
  final DateTime startDate;
  final DateTime endDate;

  const GetFritidsStatisticsParams({
    required this.startDate,
    required this.endDate,
  });

  @override
  Map<String, dynamic> toMap() => {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      };
}

/// Statistics result model
class FritidsStatistics {
  final int solenFmCount;
  final int solenEmCount;
  final int havetFmCount;
  final int havetEmCount;
  final int totalRegistrations;
  final int totalAlgebronor;

  FritidsStatistics({
    required this.solenFmCount,
    required this.solenEmCount,
    required this.havetFmCount,
    required this.havetEmCount,
  })  : totalRegistrations =
            solenFmCount + solenEmCount + havetFmCount + havetEmCount,
        totalAlgebronor =
            solenFmCount + solenEmCount + havetFmCount + havetEmCount;

  Map<String, int> toMap() => {
        'solen_fm': solenFmCount,
        'solen_em': solenEmCount,
        'havet_fm': havetFmCount,
        'havet_em': havetEmCount,
        'total_registrations': totalRegistrations,
        'total_algebronor': totalAlgebronor,
      };
}

/// Use case for getting fritids registration statistics
@lazySingleton
class GetFritidsStatisticsUseCase
    extends BaseUseCase<FritidsStatistics, GetFritidsStatisticsParams> {
  final IFritidsRepository _fritidsRepository;

  GetFritidsStatisticsUseCase(this._fritidsRepository);

  @override
  Future<Result<FritidsStatistics>> call(
      GetFritidsStatisticsParams params) async {
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

      // Get all registrations for the period
      final registrations = await _getRegistrationsForPeriod(params);

      // Calculate statistics
      final statistics = _calculateStatistics(registrations);

      return Success(statistics);
    } catch (e, stackTrace) {
      return Failure(
        UnknownError(
          message: 'Ett fel uppstod vid beräkning av statistik',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<List<FritidsPassRegistrationModel>> _getRegistrationsForPeriod(
      GetFritidsStatisticsParams params) async {
    final List<FritidsPassRegistrationModel> allRegistrations = [];

    DateTime currentDate = _normalizeDate(params.startDate);
    final endDate = _normalizeDate(params.endDate);

    while (!currentDate.isAfter(endDate)) {
      final dayRegistrations =
          await _fritidsRepository.getRegistrationsByDate(currentDate);
      allRegistrations.addAll(dayRegistrations);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return allRegistrations;
  }

  FritidsStatistics _calculateStatistics(
      List<FritidsPassRegistrationModel> registrations) {
    int solenFmCount = 0;
    int solenEmCount = 0;
    int havetFmCount = 0;
    int havetEmCount = 0;

    for (final registration in registrations) {
      if (registration.isReverted) continue;

      if (registration.group == FritidsGroup.solen) {
        if (registration.passType == PassType.fm) {
          solenFmCount++;
        } else {
          solenEmCount++;
        }
      } else if (registration.group == FritidsGroup.havet) {
        if (registration.passType == PassType.fm) {
          havetFmCount++;
        } else {
          havetEmCount++;
        }
      }
    }

    return FritidsStatistics(
      solenFmCount: solenFmCount,
      solenEmCount: solenEmCount,
      havetFmCount: havetFmCount,
      havetEmCount: havetEmCount,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
