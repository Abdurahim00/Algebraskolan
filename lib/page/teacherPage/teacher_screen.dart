import 'dart:async';

import 'package:algebra/page/teacherPage/widget/coin_calculator.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import '../../provider/student_provider.dart';
import 'widget/student_card_list.dart';
import '../student_search.dart';

const Classesnr = [
  {"image": "number0.png", "name": "Klass 0", "number": 0},
  {"image": "number1.png", "name": "Klass 1", "number": 1},
  {"image": "number2.png", "name": "Klass 2", "number": 2},
  {"image": "number3.png", "name": "Klass 3", "number": 3},
  {"image": "number4.png", "name": "Klass 4", "number": 4},
  {"image": "number5.png", "name": "Klass 5", "number": 5},
  {"image": "number6.png", "name": "Klass 6", "number": 6},
  {"image": "number7.png", "name": "Klass 7", "number": 7},
  {"image": "number8.png", "name": "Klass 8", "number": 8},
  {"image": "number9.png", "name": "Klass 9", "number": 9},
];

final GoogleSignIn googleSignIn = GoogleSignIn();

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({Key? key}) : super(key: key);

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int? selectedClass = 0;
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> refreshNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);

    final TextTheme textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // This is for when a teacher sends coins, their name will be displayed for the student.
    User? user = FirebaseAuth.instance.currentUser;
    String teacherName = user?.displayName ??
        'Anonymous'; // Default to 'Anonymous' if displayName is null

    final studentProvider =
        context.watch<StudentProvider>(); // Access the StudentProvider
    return SafeArea(
      child: Scaffold(
        key: _scaffoldkey,
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                  child: (Image.asset("assets/images/Algebraskola1.png"))),
              ListTile(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // Check the platform
                    if (Theme.of(context).platform == TargetPlatform.iOS) {
                      // Use CupertinoAlertDialog for iOS
                      return CupertinoAlertDialog(
                        title: Text("Är du säker?"),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            onPressed: () {
                              provider.googleLogout();
                              Navigator.of(context).pop();
                            },
                            child: Text("Ja"),
                          ),
                          CupertinoDialogAction(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Nej"),
                          ),
                        ],
                      );
                    } else {
                      // Fallback to AlertDialog for Android and other platforms
                      return AlertDialog(
                        title: Text("Är du säker?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              provider.googleLogout();
                              Navigator.of(context).pop();
                            },
                            child: Text("Ja"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Nej"),
                          ),
                        ],
                      );
                    }
                  },
                ),
                title: const Text(
                  "Logga ut",
                  style: TextStyle(fontFamily: 'montserrat'),
                ),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.6 - (screenHeight * 0.2) / 2, // Adjusted
              left: screenWidth * 0.5 - (screenWidth * 0.5) / 2, // Adjusted
              child: SizedBox(
                height: screenHeight * 0.2,
                width: screenWidth * 0.5,
                child: const Coin_calculator(),
              ),
            ),
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    color: const Color.fromRGBO(245, 142, 11, 1),
                  ),
                ),
                // Update the StudentListPart
                StudentListPart(
                  textTheme: textTheme,
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.33 - 10,
              child: Container(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 0.35 + 20,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: Classesnr.map((classes) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedClass = classes["number"] as int?;
                            context.read<StudentProvider>().handleClassChanged(
                                selectedClass!); // Call handleClassChanged from the StudentProvider
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                              right: 10.0,
                              top: selectedClass == classes['number'] ? 10 : 0),
                          width: MediaQuery.of(context).size.width * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Image.asset(
                                    "assets/images/${classes['image']}"),
                                const SizedBox(height: 10),
                                Flexible(
                                  child: AutoSizeText(
                                    "${classes["name"]}",
                                    style: const TextStyle(
                                        fontFamily: 'montserrat'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                elevation: 0,
                backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
                title: Center(
                  child: SizedBox(
                    width: screenWidth * 0.4, // adjust as needed
                    child: Image.asset("assets/images/Algebraskolan4.png"),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(UniconsLine.shopping_cart,
                        color: Colors.white),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: StudentSearch(),
                      ).then((studentNotifier) {
                        if (studentNotifier != null) {
                          print(
                              'Selected student: ${studentNotifier.displayName}');
                        }
                      });
                    },
                  ),
                ],
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    _scaffoldkey.currentState?.openDrawer();
                  },
                ),
              ),
            ),
            studentProvider.showButton
                ? Positioned(
                    top: MediaQuery.of(context).size.height * 0.27 - 50,
                    left: MediaQuery.of(context).size.width / 2 - 30,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Made it asynchronous
                        // Call the function and wait for it to complete
                        await studentProvider.updateAllCoins(teacherName);

                        // Hide the button immediately after it's pressed
                        studentProvider.setShowButton(false);

                        // Deselect all students when sending coins
                        studentProvider.handleDeselectAllStudents();

                        // Set a timer to reset the updated or failure status
                        Timer(const Duration(milliseconds: 1900), () {
                          studentProvider.resetUpdated();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20.0),
                        backgroundColor: Colors.blue[400],
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        alignment: Alignment.bottomLeft,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Skicka",
                        style: TextStyle(
                          fontFamily:
                              'Roboto', // Use the font family name you declared in pubspec.yaml
                          fontSize: 16, // Set the font size directly here
                        ),
                      ),
                    ),
                  )
                : Container(),
            if (studentProvider.updated)
              Container(
                // Semi-transparent overlay
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.3, // take 50% of parent width
                    heightFactor: 0.5, // take 50% of parent height
                    alignment: Alignment.topCenter,
                    child: Lottie.asset("assets/images/checkmark (2).json"),
                  ),
                ),
              ),
            if (studentProvider.failure)
              Container(
                // Semi-transparent overlay
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.3,
                    heightFactor: 0.5,
                    alignment: Alignment.topCenter,
                    child: Lottie.asset(
                        "assets/images/canceled.json"), // Your "X" animation file here
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
