import 'dart:async';

import 'package:algebra/page/teacherPage/widget/coin_calculator.dart';
import 'package:algebra/page/teacherPage/widget/student_card.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import '../../provider/student_provider.dart';
import 'widget/student_card_list.dart';
import '../student_search.dart';
import 'package:google_fonts/google_fonts.dart';

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
  GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);

    final TextTheme textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text("Är du säker?"),
                        actions: [
                          MaterialButton(
                            onPressed: () {
                              provider.googleLogout();
                              Navigator.pop(context);
                            },
                            child: Text("Ja"),
                          ),
                          MaterialButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Nej"),
                          )
                        ],
                      );
                    }),
                title: Text(
                  "Logga ut",
                  style: GoogleFonts.montserrat(),
                ),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    color: const Color.fromRGBO(245, 142, 11, 1),
                    child: Stack(
                      children: [
                        Positioned(
                          top: screenHeight * 0.007,
                          left: 0,
                          right: 0,
                          child: Center(
                            // Center widget to center the image
                            child: SizedBox(
                              // Size limiting widget
                              width: screenWidth *
                                  0.4, // 40% of screen width, adjust as per your requirement
                              child: Image.asset(
                                  "assets/images/Algebraskolan4.png"),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10.0,
                          right: 10.0,
                          child: IconButton(
                            icon: const Icon(UniconsLine.shopping_cart,
                                color: Colors.white),
                            onPressed: () {
                              showSearch(
                                context: context,
                                delegate:
                                    StudentSearch(studentProvider.students),
                              ).then((studentNotifier) {
                                if (studentNotifier != null) {
                                  print(
                                      'Selected student: ${studentNotifier.displayName}');
                                }
                              });
                            },
                          ),
                        ),
                        Positioned(
                          top: 10.0,
                          left: 10.0,
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            // your menu icon here
                            onPressed: () {
                              _scaffoldkey.currentState?.openDrawer();
                              // your menu button action here
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Update the StudentListPart
                StudentListPart(
                  textTheme: textTheme,
                ),
              ],
            ),
            Positioned(
              top: screenHeight * 0.6 - (screenHeight * 0.2) / 2, // Adjusted
              left: screenWidth * 0.5 - (screenWidth * 0.5) / 2, // Adjusted
              child: SizedBox(
                height: screenHeight * 0.2,
                width: screenWidth * 0.5,
                child: const Coin_calculator(),
              ),
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
                                    style: GoogleFonts.montserrat(),
                                    maxLines: 1,
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
            studentProvider.showButton
                ? Positioned(
                    top: MediaQuery.of(context).size.height * 0.27 - 50,
                    left: MediaQuery.of(context).size.width / 2 - 30,
                    child: ElevatedButton(
                      onPressed: () {
                        studentProvider.updateAllCoins();
                        // Hide the button immediately after it's pressed
                        studentProvider.setShowButton(false);
                        // Add this line
                        studentProvider.handleDeselectAllStudents();

                        Timer(const Duration(milliseconds: 1000), () {
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
                      child: Text(
                        "Skicka",
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ),
                  )
                : Container(),
            if (studentProvider.updated)
              Container(
                color:
                    Colors.black.withOpacity(0.5), // Semi-transparent overlay
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.3, // take 50% of parent width
                    heightFactor: 0.3, // take 50% of parent height
                    alignment: Alignment.center,
                    child: Lottie.asset("assets/images/achievement.json"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
