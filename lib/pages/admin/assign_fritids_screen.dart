import 'package:flutter/material.dart';
import '../../scripts/assign_students_to_fritids.dart';
import '../../utils/quick_assign_fritids.dart';

class AssignFritidsScreen extends StatefulWidget {
  const AssignFritidsScreen({super.key});

  @override
  State<AssignFritidsScreen> createState() => _AssignFritidsScreenState();
}

class _AssignFritidsScreenState extends State<AssignFritidsScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _quickAssign() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Tilldelar första 20 eleverna...';
    });

    try {
      final result = await quickAssignFritidsStudents();
      setState(() {
        if (result['success']) {
          _statusMessage = '✓ ${result['message']}\n'
              'Solen: ${result['solenCount']} elever\n'
              'Havet: ${result['havetCount']} elever\n'
              'Totalt: ${result['total']} elever';
        } else {
          _statusMessage = '✗ ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Fel: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignStudents() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Tilldelar elever till fritidsgrupper...';
    });

    try {
      await assignStudentsToFritids();
      setState(() {
        _statusMessage = 'Klart! Alla elever har tilldelats till Solen eller Havet.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Fel: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignByClass() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Tilldelar elever baserat på klass...';
    });

    try {
      // Example: Assign classes 0-4 to Solen, 5-9 to Havet
      await assignStudentsByClass(
        solenClasses: [0, 1, 2, 3, 4],
        havetClasses: [5, 6, 7, 8, 9],
      );
      setState(() {
        _statusMessage = 'Klart! Klass 0-4 → Solen, Klass 5-9 → Havet';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Fel: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAssignments() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Rensar alla fritidstilldelningar...';
    });

    try {
      await clearFritidsAssignments();
      setState(() {
        _statusMessage = 'Klart! Alla fritidstilldelningar har rensats.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Fel: $e';
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
        title: const Text('Tilldela Fritidsgrupper'),
        backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Administratörsverktyg för att tilldela elever till fritidsgrupper',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Quick Test Option
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Snabbtest (Rekommenderat)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tilldelar första 20 eleverna för att testa funktionen.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _quickAssign,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Snabbtilldela 20 elever'),
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

            // Option 1: Split evenly
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '☀️ Alternativ 1: Dela jämnt',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tilldelar hälften av eleverna till Solen och hälften till Havet.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _assignStudents,
                      icon: const Icon(Icons.people),
                      label: const Text('Tilldela jämnt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Option 2: By class
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌊 Alternativ 2: Baserat på klass',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Klass 0-4 → Solen ☀️\nKlass 5-9 → Havet 🌊'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _assignByClass,
                      icon: const Icon(Icons.class_),
                      label: const Text('Tilldela efter klass'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Option 3: Clear all
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗑️ Rensa alla tilldelningar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ta bort fritidsgrupp från alla elever.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _clearAssignments,
                      icon: const Icon(Icons.delete),
                      label: const Text('Rensa alla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

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
