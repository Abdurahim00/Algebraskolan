import 'package:flutter/material.dart';
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
