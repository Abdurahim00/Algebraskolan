import 'dart:async';

import 'package:algebra/page/teacherPage/widget/drawer.dart';
import 'package:algebra/page/teacherPage/widget/coin_calculator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../provider/student_provider.dart';
import 'widget/student_card_list.dart';
import '../searchPage/student_search.dart';
import 'dart:math' as math;

const classesNr = [
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
  const TeacherScreen({super.key});

  @override
  TeacherScreenState createState() => TeacherScreenState();
}

bool isTablet(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 600; // You can adjust this threshold as needed
}

class TeacherScreenState extends State<TeacherScreen> {
  int? selectedClass = 0;
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> refreshNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxCardWidth = 160.0; // Maximum card width, adjust as needed

    double cardWidth = math.min(screenWidth * 0.25, maxCardWidth);

    const double maxCardHeight = 100.0; // Maximum card height, adjust as needed

    double cardHeight = math.min(cardWidth * (3 / 2), maxCardHeight);

    // This is for when a teacher sends coins, their name will be displayed for the student.
    User? user = FirebaseAuth.instance.currentUser;
    String teacherName = user?.displayName ??
        'Anonymous'; // Default to 'Anonymous' if displayName is null

    final studentProvider =
        context.watch<StudentProvider>(); // Access the StudentProvider
    return SafeArea(
      child: Scaffold(
        key: _scaffoldkey,
        drawer: const AppDrawer(),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            if (studentProvider.showCoinCalculator)
              Positioned(
                top: screenHeight * 0.6 - (screenHeight * 0.2) / 2, // Adjusted
                left: screenWidth * 0.5 - (screenWidth * 0.5) / 2, // Adjusted
                child: SizedBox(
                  height: screenHeight * 0.1,
                  width: screenWidth * 0.5,
                  child: const Coin_calculator(),
                ),
              ),
            Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Color.fromARGB(255, 245, 142, 11),
                  ),
                ),
                // Update the StudentListPart
                StudentListPart(
                  textTheme: textTheme,
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25 - 10,
              child: Container(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                width: MediaQuery.of(context).size.width,
                height: isTablet(context)
                    ? MediaQuery.of(context).size.width * 0.3 + 10
                    // Shorter height for tablets
                    : MediaQuery.of(context).size.width * 0.35 +
                        20, // Original height for mobile
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: classesNr
                      .map((classes) => GestureDetector(
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
                                  top: selectedClass == classes['number']
                                      ? 10
                                      : 0),
                              width: cardWidth,
                              height: cardHeight, // Apply the calculated height
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30.0),
                                boxShadow: selectedClass == classes['number']
                                    ? [
                                        BoxShadow(
                                          color: Colors
                                              .blue.shade100, // Glow color
                                          offset: const Offset(0, 2),
                                          blurRadius:
                                              10.0, // Increase the blur radius for a larger glow
                                          spreadRadius: 5.0,
                                        ),
                                      ]
                                    : const [
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
                          ))
                      .toList(),
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
                    width: isTablet(context)
                        ? screenWidth * 0.18
                        : screenWidth * 0.4, // Adjust size for tablet
                    child: Image.asset("assets/images/Algebraskolan4.png"),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
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
            studentProvider.isUpdatingCoins
                ? Center(
                    child: Lottie.asset("assets/images/Circle Loading.json",
                        width: screenWidth * 0.3),
                  )
                : studentProvider.showButton
                    ? Positioned(
                        top: MediaQuery.of(context).size.height * 0.2 - 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Disable the button and show loading indicator
                              studentProvider.setShowButton(false);
                              studentProvider.setIsUpdatingCoins(true);

                              // Call the function and wait for it to complete
                              await studentProvider.updateAllCoins(teacherName);

                              // Hide loading indicator and handle the outcome
                              studentProvider.setIsUpdatingCoins(false);
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
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Colors.white),
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
                    child: Lottie.asset(
                      "assets/images/checkmark (2).json",
                    ),
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
