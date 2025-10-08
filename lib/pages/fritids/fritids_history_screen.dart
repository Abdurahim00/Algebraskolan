import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/fritids_history_provider.dart';
import '../../domain/models/fritids_group.dart';
import '../../domain/models/pass_type.dart';
import '../../widgets/skeleton_loading.dart';
import 'widgets/fritids_statistics_widget.dart';
import 'widgets/registration_list_item.dart';
import 'widgets/fritids_attendance_view.dart';

class FritidsHistoryScreen extends StatefulWidget {
  const FritidsHistoryScreen({super.key});

  @override
  State<FritidsHistoryScreen> createState() => _FritidsHistoryScreenState();
}

class _FritidsHistoryScreenState extends State<FritidsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FritidsHistoryProvider>().fetchRegistrations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final provider = context.read<FritidsHistoryProvider>();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: provider.startDate,
        end: provider.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(245, 142, 11, 1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
      provider.fetchRegistrations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<FritidsHistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fritids Historik'),
        backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Historik', icon: Icon(Icons.history)),
            Tab(text: 'Närvaro', icon: Icon(Icons.how_to_reg)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              historyProvider.fetchRegistrations();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(historyProvider),
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(FritidsHistoryProvider historyProvider) {
    return CustomScrollView(
      slivers: [
        // Statistics card
        if (historyProvider.statistics != null)
          SliverToBoxAdapter(
            child: FritidsStatisticsWidget(
              statistics: historyProvider.statistics!,
            ),
          ),
        // Filters
        SliverToBoxAdapter(
          child: _buildFilters(context, historyProvider),
        ),
        // Registrations list
        _buildRegistrationsSliverList(historyProvider),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    return const FritidsAttendanceView();
  }

  Widget _buildFilters(BuildContext context, FritidsHistoryProvider provider) {
    final dateFormat = DateFormat('d MMM yyyy', 'sv_SE');

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Date range selector
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(provider.startDate)} - ${dateFormat.format(provider.endDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Group and Pass type filters
          Row(
            children: [
              Expanded(
                child: _buildGroupFilter(provider),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPassTypeFilter(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilter(FritidsHistoryProvider provider) {
    return DropdownButtonFormField<FritidsGroup?>(
      value: provider.selectedGroup,
      decoration: InputDecoration(
        labelText: 'Grupp',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<FritidsGroup?>(
          value: null,
          child: Text('Alla grupper'),
        ),
        ...FritidsGroup.values.map((group) {
          return DropdownMenuItem<FritidsGroup?>(
            value: group,
            child: Text(group.displayName),
          );
        }),
      ],
      onChanged: (value) {
        provider.setGroupFilter(value);
        provider.fetchRegistrations();
      },
    );
  }

  Widget _buildPassTypeFilter(FritidsHistoryProvider provider) {
    return DropdownButtonFormField<PassType?>(
      value: provider.selectedPassType,
      decoration: InputDecoration(
        labelText: 'Pass',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<PassType?>(
          value: null,
          child: Text('Alla pass'),
        ),
        ...PassType.values.map((passType) {
          return DropdownMenuItem<PassType?>(
            value: passType,
            child: Text(passType.fullDisplayName),
          );
        }),
      ],
      onChanged: (value) {
        provider.setPassTypeFilter(value);
        provider.fetchRegistrations();
      },
    );
  }

  Widget _buildRegistrationsSliverList(FritidsHistoryProvider provider) {
    if (provider.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const SkeletonHistoryItem(),
            childCount: 8,
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchRegistrations(),
                child: const Text('Försök igen'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.registrations.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Inga registreringar hittades',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Group registrations by date
    final groupedRegistrations = provider.getRegistrationsGroupedByDate();
    final sortedDates = groupedRegistrations.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dateKey = sortedDates[index];
            final registrations = groupedRegistrations[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(245, 142, 11, 1),
                    ),
                  ),
                ),
                // Registrations for this date
                ...registrations.map((registration) {
                  return RegistrationListItem(registration: registration);
                }),
                const SizedBox(height: 8),
              ],
            );
          },
          childCount: sortedDates.length,
        ),
      ),
    );
  }
}
