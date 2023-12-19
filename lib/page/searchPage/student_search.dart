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

    final Future<List<ValueNotifier<Student>>> studentsFuture = query.isEmpty
        ? studentProvider.fetchAllStudentsSortedByCoins()
        : studentProvider.fetchSearch(query);

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
          return ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              final studentNotifier = snapshot.data![index];
              final student = studentNotifier.value;
              return ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${student.displayName} (Klass ${student.classNumber})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text('${student.coins} '),
                        const Icon(Icons.circle, color: Colors.orange),
                      ],
                    ),
                  ],
                ),
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
          backgroundColor: Colors.white,
          title:
              Text('Ange Algebronor för ${studentNotifier.value.displayName}'),
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: coinController,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.only(),
                  // Border style when TextField is enabled
                  borderSide: BorderSide(width: 2.0),
                ),
                border: OutlineInputBorder(),
                labelText: 'Ange Algebronor',
                labelStyle: TextStyle(
                  color: Colors.black, // Default label color
                ),
              ),
              cursorColor: Colors.black,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
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

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Tar bort algebronor..."),
                  ],
                ),
              ),
            );
          },
        );

        studentNotifier.value.localCoins.value -= coinsToRemove;
        final teacherName = googleSignInProvider.user?.displayName ?? "Unknown";
        try {
          await studentProvider.updateStudentCoins(
              studentNotifier, teacherName);
          Navigator.pop(context); // Close the progress dialog
          coinController.clear();
          Navigator.of(context).pop(); // Close the alert dialog
          _showSuccessToast('Du har tagit bort $coinsToRemove algebronor');
        } catch (e) {
          Navigator.pop(context); // Close the progress dialog
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
        if (coins <= 0) {
          _showToast('Du kan inte skicka 0 algebronor.');
          return;
        }
        if (coins > 9999) {
          _showToast('Du kan inte skicka mer än 9999 algebronor.');
          return;
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Skickar algebronor..."),
                  ],
                ),
              ),
            );
          },
        );
        studentNotifier.value.localCoins.value += coins;
        final teacherName = googleSignInProvider.user?.displayName ?? "Unknown";
        try {
          await studentProvider.updateStudentCoins(
              studentNotifier, teacherName);
          Navigator.pop(context); // Close the progress dialog
          coinController.clear();
          Navigator.of(context).pop(); // Close the alert dialog
          _showSuccessToast('Du har skickat $coins algebronor');
        } catch (e) {
          Navigator.pop(context); // Close the progress dialog
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
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
