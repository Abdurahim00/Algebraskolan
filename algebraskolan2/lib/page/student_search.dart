import 'package:algebra/page/student.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentSearch extends SearchDelegate<Student?> {
  final List<ValueNotifier<Student>> students;

  StudentSearch(this.students);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  StudentProvider provider = StudentProvider();

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<ValueNotifier<Student>>>(
      future: provider.fetchSearch(
        query,
      ),
      builder: (BuildContext context,
          AsyncSnapshot<List<ValueNotifier<Student>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            color: Colors.orange,
          ));
        } else {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          else {
            final results = snapshot.data;
            return ListView.builder(
              itemCount: results?.length,
              itemBuilder: (context, index) {
                final studentNotifier = results![index];
                final student = studentNotifier.value;
                return ListTile(
                  title: Text(
                      '${student.displayName} (Klass ${student.classNumber})'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final coinController = TextEditingController();
                        return AlertDialog(
                          title: Text('Ange mynt för ${student.displayName}'),
                          content: TextField(
                            controller: coinController,
                            decoration: const InputDecoration(
                              labelText: 'Ange mynt',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Skicka'),
                              onPressed: () {
                                final coins =
                                    int.tryParse(coinController.text) ?? 0;
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(student.uid)
                                    .update(
                                        {'coins': FieldValue.increment(coins)});
                                coinController.clear();
                                Navigator.of(context).pop();
                                close(context, student);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          }
        }
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Just return an empty container here
    return Container();
  }
}