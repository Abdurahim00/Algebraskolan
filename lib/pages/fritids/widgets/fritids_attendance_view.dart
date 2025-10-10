import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../provider/fritids_attendance_provider.dart';
import '../../../domain/models/fritids_group.dart';

class FritidsAttendanceView extends StatefulWidget {
  const FritidsAttendanceView({super.key});

  @override
  State<FritidsAttendanceView> createState() => _FritidsAttendanceViewState();
}

class _FritidsAttendanceViewState extends State<FritidsAttendanceView> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FritidsAttendanceProvider>().fetchAttendance(_selectedDate);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (mounted) {
        context
            .read<FritidsAttendanceProvider>()
            .fetchAttendance(_selectedDate);
      }
    }
  }

  Future<void> _exportToCSV() async {
    final provider = context.read<FritidsAttendanceProvider>();
    final attendanceData = provider.attendanceData;

    if (attendanceData == null) return;

    // Prepare CSV data
    List<List<dynamic>> rows = [];

    // Header
    rows.add(['Klass', 'Namn', 'Grupp', 'FM Status', 'EM Status']);

    // Sort by class
    final sortedByClass = Map<int, List<Map<String, dynamic>>>();
    for (var student in attendanceData) {
      final classNum = student['classNum'] as int;
      if (!sortedByClass.containsKey(classNum)) {
        sortedByClass[classNum] = [];
      }
      sortedByClass[classNum]!.add(student);
    }

    // Add rows
    for (var classNum in sortedByClass.keys.toList()..sort()) {
      final students = sortedByClass[classNum]!;
      for (var student in students) {
        final group = student['fritidsGroup'] as FritidsGroup?;
        rows.add([
          'Klass $classNum',
          student['name'],
          group != null ? group.displayName : 'Ingen grupp',
          student['hasFM'] ? 'Närvarande' : 'Frånvarande',
          student['hasEM'] ? 'Närvarande' : 'Frånvarande',
        ]);
      }
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final fileName =
          'fritids_narvaro_${dateFormat.format(_selectedDate)}.csv';

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Fritids Närvaro - ${dateFormat.format(_selectedDate)}',
        sharePositionOrigin: Rect.fromLTWH(
          0,
          0,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height * 0.5,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Närvarolista exporterad!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fel vid export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FritidsAttendanceProvider>();
    final dateFormat = DateFormat('d MMMM yyyy', 'sv_SE');

    return Column(
      children: [
        // Date selector and export button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              InkWell(
                onTap: _selectDate,
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
                          dateFormat.format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                    provider.attendanceData != null && !provider.isLoading
                        ? _exportToCSV
                        : null,
                icon: const Icon(Icons.file_download),
                label: const Text('Exportera till CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
        // Attendance list
        Expanded(
          child: _buildAttendanceList(provider),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(FritidsAttendanceProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(245, 142, 11, 1),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
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
              onPressed: () => provider.fetchAttendance(_selectedDate),
              child: const Text('Försök igen'),
            ),
          ],
        ),
      );
    }

    final attendanceData = provider.attendanceData;
    if (attendanceData == null || attendanceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ingen data hittades',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group by class
    final groupedByClass = <int, List<Map<String, dynamic>>>{};
    for (var student in attendanceData) {
      final classNum = student['classNum'] as int;
      if (!groupedByClass.containsKey(classNum)) {
        groupedByClass[classNum] = [];
      }
      groupedByClass[classNum]!.add(student);
    }

    final sortedClasses = groupedByClass.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedClasses.length,
      itemBuilder: (context, index) {
        final classNum = sortedClasses[index];
        final students = groupedByClass[classNum]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(245, 142, 11, 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Klass $classNum',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${students.length} elever',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Students in this class
            ...students.map((student) {
              final group = student['fritidsGroup'] as FritidsGroup?;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            const Color.fromRGBO(245, 142, 11, 0.2),
                        child: Text(
                          (student['name'] as String)[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color.fromRGBO(245, 142, 11, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (group != null)
                              Text(
                                group == FritidsGroup.solen
                                    ? '☀️ Solen'
                                    : '🌊 Havet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // FM status
                      _buildPassStatusChip(
                        'FM',
                        student['hasFM'] as bool,
                      ),
                      const SizedBox(width: 8),
                      // EM status
                      _buildPassStatusChip(
                        'EM',
                        student['hasEM'] as bool,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildPassStatusChip(String label, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
