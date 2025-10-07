import 'package:injectable/injectable.dart';
import '../../../core/result/result.dart';
import '../../models/fritids_pass_registration_model.dart';
import '../../models/fritids_group.dart';
import '../../models/pass_type.dart';
import '../../repositories/i_fritids_repository.dart';
import '../base_usecase.dart';

/// Parameters for getting today's fritids registrations
class GetTodayFritidsRegistrationsParams extends Params {
  final FritidsGroup? group;
  final PassType? passType;

  const GetTodayFritidsRegistrationsParams({
    this.group,
    this.passType,
  });

  @override
  Map<String, dynamic> toMap() => {
        if (group != null) 'group': group!.toValue(),
        if (passType != null) 'passType': passType!.toValue(),
      };
}

/// Use case for getting today's fritids registrations
@lazySingleton
class GetTodayFritidsRegistrationsUseCase extends BaseUseCase<
    List<FritidsPassRegistrationModel>, GetTodayFritidsRegistrationsParams> {
  final IFritidsRepository _fritidsRepository;

  GetTodayFritidsRegistrationsUseCase(this._fritidsRepository);

  @override
  Future<Result<List<FritidsPassRegistrationModel>>> call(
      GetTodayFritidsRegistrationsParams params) async {
    try {
      List<FritidsPassRegistrationModel> registrations;

      if (params.group != null && params.passType != null) {
        // Get registrations for specific group and pass type
        registrations =
            await _fritidsRepository.getTodayRegistrationsByGroupAndPass(
          params.group!,
          params.passType!,
        );
      } else if (params.group != null) {
        // Get registrations for specific group
        registrations =
            await _fritidsRepository.getTodayRegistrationsByGroup(params.group!);
      } else {
        // Get all registrations for today
        registrations =
            await _fritidsRepository.getRegistrationsByDate(DateTime.now());
      }

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
}
