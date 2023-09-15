import 'package:algebra/page/student.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:provider/provider.dart';

class StudentSearch extends SearchDelegate<Student?> {
  final GoogleSignInProvider googleSignInProvider =
      GoogleSignInProvider.instance;

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

  @override
  Widget buildSuggestions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Get the StudentProvider instance
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);

    // Use the fetchSearch method with the current query
    final studentsFuture = studentProvider.fetchSearch(query);

    return FutureBuilder<List<ValueNotifier<Student>>>(
      future: studentsFuture,
      builder: (BuildContext context,
          AsyncSnapshot<List<ValueNotifier<Student>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset("assets/images/Circle Loading.json",
                width: screenWidth * 0.2),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final results = snapshot.data ?? [];
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final studentNotifier = results[index];
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
                        content: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            controller: coinController,
                            decoration: const InputDecoration(
                              labelText: 'Ange mynt',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Skicka'),
                            onPressed: () async {
                              final coins =
                                  int.tryParse(coinController.text) ?? 0;
                              studentNotifier.value.localCoins.value = coins;

                              final teacherName =
                                  googleSignInProvider.user?.displayName ??
                                      "Unknown";

                              try {
                                await studentProvider.updateStudentCoins(
                                    studentNotifier, teacherName);
                                coinController.clear();
                                Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error updating coins: $e')));
                              }
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
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }
}
