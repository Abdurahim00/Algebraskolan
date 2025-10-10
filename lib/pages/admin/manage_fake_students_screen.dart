import 'package:flutter/material.dart';
import '../../utils/create_fake_students.dart';

class ManageFakeStudentsScreen extends StatefulWidget {
  const ManageFakeStudentsScreen({super.key});

  @override
  State<ManageFakeStudentsScreen> createState() =>
      _ManageFakeStudentsScreenState();
}

class _ManageFakeStudentsScreenState extends State<ManageFakeStudentsScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _createFakeStudents() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating fake students...';
    });

    try {
      final result = await createFakeStudentsForFritids();
      setState(() {
        if (result['success']) {
          _statusMessage = '✅ ${result['message']}\n\n'
              '☀️ Solen: ${result['solenCount']} students\n'
              '🌊 Havet: ${result['havetCount']} students\n'
              '📊 Total: ${result['total']} students\n\n'
              'These are clearly marked as test data and won\'t interfere with real students.';
        } else {
          _statusMessage = '❌ ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFakeStudents() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting fake students...';
    });

    try {
      final result = await deleteFakeStudents();
      setState(() {
        if (result['success']) {
          _statusMessage = '🗑️ ${result['message']}\n\n'
              'Deleted ${result['deletedCount']} fake students.';
        } else {
          _statusMessage = '❌ ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fake Students'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create fake test students for fritids testing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 What this creates:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 5 fake students in Solen ☀️ group'),
                    const Text('• 5 fake students in Havet 🌊 group'),
                    const Text('• All marked as "isTestStudent: true"'),
                    const Text(
                        '• Class number 99 (won\'t conflict with real classes)'),
                    const Text('• Clear "Test" naming to avoid confusion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Create Fake Students',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Creates 10 fake students for fritids testing. Safe to use with real data.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createFakeStudents,
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Create Fake Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗑️ Delete Fake Students',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Removes all fake students marked as test data.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteFakeStudents,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All Fake Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
