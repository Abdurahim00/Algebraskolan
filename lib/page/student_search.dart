import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/student_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:algebra/page/student.dart';

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
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
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
          _showToast("Error: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final results = snapshot.data ?? [];
          // Filter results based on full name match or partial match
          final filteredResults = results.where((studentNotifier) {
            final studentName = studentNotifier.value.displayName.toLowerCase();
            final lowerCaseQuery = query.toLowerCase();
            return query.isNotEmpty &&
                (studentName == lowerCaseQuery ||
                    studentName.contains(lowerCaseQuery));
          }).toList();

          return ListView.builder(
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final studentNotifier = filteredResults[index];
              final student = studentNotifier.value;
              return ListTile(
                title: Text(
                    '${student.displayName} (Klass ${student.classNumber})'),
                onTap: () {
                  _showStudentDialog(context, studentNotifier, studentProvider);
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

  void _showStudentDialog(BuildContext context,
      ValueNotifier<Student> studentNotifier, StudentProvider studentProvider) {
    final coinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ange mynt för ${studentNotifier.value.displayName}'),
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: coinController,
              decoration: const InputDecoration(labelText: 'Ange mynt'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter
                    .digitsOnly, // Only numbers can be entered
              ],
            ),
          ),
          actions: [
            _buildRemoveButton(
                context, studentNotifier, studentProvider, coinController),
            _buildSendButton(
                context, studentNotifier, studentProvider, coinController),
          ],
        );
      },
    );
  }

  Widget _buildRemoveButton(
      BuildContext context,
      ValueNotifier<Student> studentNotifier,
      StudentProvider studentProvider,
      TextEditingController coinController) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
      ),
      onPressed: () async {
        final coinsToRemove = int.tryParse(coinController.text) ?? 0;

        // Check if the coins are within the allowed range
        if (coinsToRemove <= 0) {
          _showToast('Du kan inte ta bort 0 algebronor.');
          return;
        }
        if (coinsToRemove > 9999) {
          _showToast('Du kan inte ta bort mer än 9999 algebronor.');
          return;
        }

        if (studentNotifier.value.coins < coinsToRemove) {
          _showToast('Eleven har inte tillräckligt med algebronor.');
          return;
        }
        studentNotifier.value.localCoins.value -= coinsToRemove;
        final teacherName = googleSignInProvider.user?.displayName ?? "Unknown";
        try {
          await studentProvider.updateStudentCoins(
              studentNotifier, teacherName);
          coinController.clear();
          Navigator.of(context).pop();
        } catch (e) {
          _showToast('Error updating coins: $e');
        }
      },
      child: const Text('Ta bort'),
    );
  }

  Widget _buildSendButton(
      BuildContext context,
      ValueNotifier<Student> studentNotifier,
      StudentProvider studentProvider,
      TextEditingController coinController) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      onPressed: () async {
        final coins = int.tryParse(coinController.text) ?? 0;
        // Check if the coins are within the allowed range
        if (coins <= 0) {
          _showToast('Du kan inte skicka 0 algebronor.');
          return;
        }
        if (coins > 9999) {
          _showToast('Du kan inte skicka mer än 9999 algebronor.');
          return;
        }

        studentNotifier.value.localCoins.value += coins;
        final teacherName = googleSignInProvider.user?.displayName ?? "Unknown";
        try {
          await studentProvider.updateStudentCoins(
              studentNotifier, teacherName);
          coinController.clear();
          Navigator.of(context).pop();
        } catch (e) {
          _showToast('Error updating coins: $e');
        }
      },
      child: const Text('Skicka'),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
