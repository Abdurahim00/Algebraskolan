import 'package:flutter/material.dart';
import 'package:algebra/pages/admin/seed_database_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMenu extends StatelessWidget {
  const AdminMenu({Key? key}) : super(key: key);

  Future<void> _fixListorUser(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Delete the fake teacher document
      await firestore.collection('users').doc('teacher_listor_dev').delete();

      // 2. Update the real Google user to be a teacher
      await firestore.collection('users').doc('XTutGYZ3GRSCCIQLekQFa8SxgnM2').update({
        'role': 'teacher',
        'classNumber': -1,
        'coins': 9999,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Also delete other fake teacher accounts if they exist
      final fakeTeachers = ['teacher_one_dev', 'teacher_two_dev'];
      for (var fakeId in fakeTeachers) {
        try {
          await firestore.collection('users').doc(fakeId).delete();
        } catch (e) {
          // Ignore if doesn't exist
        }
      }

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ User fixed! listor@algebrautbildning.se is now a teacher'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Menu'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Admin Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeedDatabaseScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.storage),
              label: const Text('Seed Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fixListorUser(context),
              icon: const Icon(Icons.build),
              label: const Text('Fix Listor User'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}