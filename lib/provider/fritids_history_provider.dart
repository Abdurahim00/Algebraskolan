import 'package:flutter/material.dart';
import '../core/di/injection_container.dart';
import '../domain/models/fritids_group.dart';
import '../domain/models/pass_type.dart';
import '../domain/models/fritids_pass_registration_model.dart';
import '../domain/usecases/fritids/get_registrations_by_period_usecase.dart';
import '../domain/usecases/fritids/get_fritids_statistics_usecase.dart';

class FritidsHistoryProvider with ChangeNotifier {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  FritidsGroup? _selectedGroup;
  PassType? _selectedPassType;

  List<FritidsPassRegistrationModel> _registrations = [];
  FritidsStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  FritidsGroup? get selectedGroup => _selectedGroup;
  PassType? get selectedPassType => _selectedPassType;
  List<FritidsPassRegistrationModel> get registrations => [..._registrations];
  FritidsStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set date range
  void setDateRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      _errorMessage = 'Slutdatum måste vara efter startdatum';
      notifyListeners();
      return;
    }

    _startDate = start;
    _endDate = end;
    _errorMessage = null;
    notifyListeners();
  }

  // Set group filter
  void setGroupFilter(FritidsGroup? group) {
    _selectedGroup = group;
    _errorMessage = null;
    notifyListeners();
  }

  // Set pass type filter
  void setPassTypeFilter(PassType? passType) {
    _selectedPassType = passType;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedGroup = null;
    _selectedPassType = null;
    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch registrations based on current filters
  Future<void> fetchRegistrations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print('FritidsHistoryProvider: Fetching registrations from ${_startDate} to ${_endDate}');
    print('FritidsHistoryProvider: Group filter: $_selectedGroup, PassType filter: $_selectedPassType');

    try {
      // Fetch registrations
      final registrationsUseCase = InjectionContainer.getRegistrationsByPeriodUseCase;
      final registrationsResult = await registrationsUseCase(
        GetRegistrationsByPeriodParams(
          startDate: _startDate,
          endDate: _endDate,
          group: _selectedGroup,
          passType: _selectedPassType,
        ),
      );

      // Fetch statistics
      final statisticsUseCase = InjectionContainer.getFritidsStatisticsUseCase;
      final statisticsResult = await statisticsUseCase(
        GetFritidsStatisticsParams(
          startDate: _startDate,
          endDate: _endDate,
        ),
      );

      registrationsResult.fold(
        onSuccess: (data) {
          print('FritidsHistoryProvider: Found ${data.length} registrations');
          _registrations = data;
        },
        onFailure: (error) {
          print('FritidsHistoryProvider: Error fetching registrations: ${error.message}');
          _errorMessage = 'Kunde inte hämta registreringar: ${error.message}';
          _registrations = [];
        },
      );

      statisticsResult.fold(
        onSuccess: (stats) {
          print('FritidsHistoryProvider: Statistics - Total: ${stats.totalRegistrations}');
          _statistics = stats;
        },
        onFailure: (error) {
          print('FritidsHistoryProvider: Error fetching statistics: ${error.message}');
          _statistics = null;
        },
      );
    } catch (e, stackTrace) {
      print('FritidsHistoryProvider: Unexpected error: $e');
      print('StackTrace: $stackTrace');
      _errorMessage = 'Ett oväntat fel uppstod: $e';
      _registrations = [];
      _statistics = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get registrations grouped by date
  Map<String, List<FritidsPassRegistrationModel>> getRegistrationsGroupedByDate() {
    final Map<String, List<FritidsPassRegistrationModel>> grouped = {};

    for (final registration in _registrations) {
      final dateKey = _formatDate(registration.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(registration);
    }

    return grouped;
  }

  // Format date for grouping
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate == today) {
      return 'Idag';
    } else if (normalizedDate == yesterday) {
      return 'Igår';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
