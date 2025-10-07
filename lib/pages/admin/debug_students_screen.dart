import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugStudentsScreen extends StatefulWidget {
  const DebugStudentsScreen({super.key});

  @override
  State<DebugStudentsScreen> createState() => _DebugStudentsScreenState();
}

class _DebugStudentsScreenState extends State<DebugStudentsScreen> {
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _solenStudents = [];
  List<Map<String, dynamic>> _havetStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch all students
      final allSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final all = allSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['displayName'] ?? 'Unknown',
          'class': data['classNumber'] ?? '?',
          'fritidsGroup': data['fritidsGroup'] ?? 'NONE',
        };
      }).toList();

      final solen = all.where((s) => s['fritidsGroup'] == 'solen').toList();
      final havet = all.where((s) => s['fritidsGroup'] == 'havet').toList();

      setState(() {
        _allStudents = all;
        _solenStudents = solen;
        _havetStudents = havet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Students'),
        backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildSection('☀️ Solen', _solenStudents, Colors.orange),
                  const SizedBox(height: 16),
                  _buildSection('🌊 Havet', _havetStudents, Colors.blue),
                  const SizedBox(height: 16),
                  _buildSection('❌ Inte tilldelade',
                    _allStudents.where((s) => s['fritidsGroup'] == 'NONE').toList(),
                    Colors.grey,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sammanfattning',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Totalt antal elever: ${_allStudents.length}'),
            Text('☀️ Solen: ${_solenStudents.length} elever'),
            Text('🌊 Havet: ${_havetStudents.length} elever'),
            Text('❌ Inte tilldelade: ${_allStudents.where((s) => s['fritidsGroup'] == 'NONE').length} elever'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> students, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${students.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Divider(),
            if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Inga elever'),
              )
            else
              ...students.map((student) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      student['name'].toString()[0],
                      style: TextStyle(color: color),
                    ),
                  ),
                  title: Text(student['name']),
                  trailing: Text('Klass ${student['class']}'),
                );
              }),
          ],
        ),
      ),
    );
  }
}
