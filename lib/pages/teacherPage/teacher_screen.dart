import 'dart:async';

import 'package:algebra/pages/teacherPage/widget/drawer.dart';
import 'package:algebra/pages/teacherPage/widget/coin_calculator.dart';
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
import '../../core/di/injection_container.dart';
import '../../domain/usecases/coins/revert_batch_transaction_usecase.dart';
import '../../widgets/revert_transaction_dialog.dart';

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

  Future<void> _handleRevertTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get the last batch transaction
      final getLastBatchUseCase =
          InjectionContainer.getLastBatchTransactionUseCase;
      final result = await getLastBatchUseCase(
        GetLastBatchTransactionParams(teacherId: user.uid),
      );

      await result.fold(
        onSuccess: (lastTransaction) async {
          if (!mounted) return;

          // Show the revert dialog
          await showDialog(
            context: context,
            builder: (context) => RevertTransactionDialog(
              lastTransaction: lastTransaction,
              onConfirm: () async {
                // Close the confirm dialog first
                final navigatorContext = Navigator.of(context);
                navigatorContext.pop();

                if (lastTransaction?.id != null) {
                  // Show loading indicator and save its context
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => WillPopScope(
                      onWillPop: () async => false,
                      child: Center(
                        child: Lottie.asset(
                          "assets/images/Circle Loading.json",
                          width: MediaQuery.of(context).size.width * 0.3,
                        ),
                      ),
                    ),
                  );

                  // Revert the transaction
                  final revertUseCase =
                      InjectionContainer.revertBatchTransactionUseCase;
                  final revertResult = await revertUseCase(
                    RevertBatchTransactionParams(
                      batchId: lastTransaction!.id,
                      teacherId: user.uid,
                    ),
                  );

                  // Close loading dialog using navigator
                  if (mounted) navigatorContext.pop();

                  if (mounted) {
                    await revertResult.fold(
                      onSuccess: (_) async {
                        // Show success dialog with animation and text
                        print('Showing success dialog...');
                        showDialog(
                          context: navigatorContext.context,
                          barrierDismissible: false,
                          builder: (successContext) => WillPopScope(
                            onWillPop: () async => false,
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: GestureDetector(
                                onTap: () {
                                  print('Dialog tapped, closing...');
                                  Navigator.of(successContext).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        width: 150,
                                        child: Lottie.asset(
                                          "assets/images/checkmark (2).json",
                                          repeat: false,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Transaktionen har ångrats!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Algebronorna har återställts',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Tryck för att stänga',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );

                        // Close success dialog after animation
                        print('Waiting 2.5 seconds before auto-close...');
                        await Future.delayed(
                            const Duration(milliseconds: 2500));
                        print(
                            'Attempting to close dialog... mounted: $mounted');
                        if (mounted) {
                          try {
                            navigatorContext.pop();
                            print('Dialog closed successfully');
                          } catch (e) {
                            print('Error closing dialog: $e');
                          }
                        }

                        // Refresh students to show updated coins
                        if (mounted) {
                          context
                              .read<StudentProvider>()
                              .fetchStudents(selectedClass ?? 0);
                        }
                      },
                      onFailure: (error) async {
                        // Show error dialog with animation and text
                        showDialog(
                          context: navigatorContext.context,
                          barrierDismissible: false,
                          builder: (errorContext) => WillPopScope(
                            onWillPop: () async => false,
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(errorContext).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        width: 150,
                                        child: Lottie.asset(
                                          "assets/images/canceled.json",
                                          repeat: false,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Något gick fel!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        error.message,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Tryck för att stänga',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );

                        // Close error dialog after animation
                        await Future.delayed(
                            const Duration(milliseconds: 2500));
                        if (mounted) navigatorContext.pop();
                      },
                    );
                  }
                }
              },
            ),
          );
        },
        onFailure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fel: ${error.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ett oväntat fel uppstod: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double getScreenSizeInInches(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    var pixelRatio = MediaQuery.of(context).devicePixelRatio;

    var widthInches = screenWidth / pixelRatio;
    var heightInches = screenHeight / pixelRatio;

    var diagonalInches =
        math.sqrt((widthInches * widthInches) + (heightInches * heightInches));
    return diagonalInches;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxCardWidth = 160.0; // Maximum card width, adjust as needed

    double cardWidth = math.min(screenWidth * 0.25, maxCardWidth);

    const double maxCardHeight = 100.0; // Maximum card height, adjust as needed

    double cardHeight = math.min(cardWidth * (3 / 2), maxCardHeight);

    // Get the screen size in inches
    double screenSizeInInches = getScreenSizeInInches(context);

    // Define sizes based on screen size
    bool isSmallScreen = screenSizeInInches < 5.0;

    double coinCalculatorHeight =
        isSmallScreen ? screenHeight * 0.08 : screenHeight * 0.1;
    double coinCalculatorWidth =
        isSmallScreen ? screenWidth * 0.4 : screenWidth * 0.5;

    double skickaButtonPadding = isSmallScreen ? 10.0 : 20.0;
    double skickaButtonFontSize = isSmallScreen ? 14.0 : 16.0;

    // This is for when a teacher sends coins, their name will be displayed for the student.
    User? user = FirebaseAuth.instance.currentUser;
    String teacherName = user?.displayName ??
        'Anonymous'; // Default to 'Anonymous' if displayName is null

    final studentProvider =
        context.watch<StudentProvider>(); // Access the StudentProvider
    return Scaffold(
      key: _scaffoldkey,
      drawer: AppDrawer(
        onRevertTransaction: _handleRevertTransaction,
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (studentProvider.showCoinCalculator)
            Positioned(
              top: screenHeight * 0.65 - (screenHeight * 0.2) / 2, // Adjusted
              left: screenWidth * 0.5 - (screenWidth * 0.5) / 2, // Adjusted
              child: SizedBox(
                height: coinCalculatorHeight,
                width: coinCalculatorWidth,
                child: const Coin_calculator(),
              ),
            ),
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color.fromARGB(255, 245, 142, 11),
                ),
              ),
              // Update the StudentListPart
              StudentListPart(
                textTheme: textTheme,
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28 - 10,
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              width: MediaQuery.of(context).size.width,
              height: isTablet(context)
                  ? MediaQuery.of(context).size.width * 0.3 + 10
                  : MediaQuery.of(context).size.width * 0.35 + 20,
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
                            height: cardHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0),
                              boxShadow: selectedClass == classes['number']
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.blue.shade100, // Glow color
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
                      if (studentNotifier != null) {}
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
                      top: MediaQuery.of(context).size.height * 0.22 - 50,
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
                            padding: EdgeInsets.all(skickaButtonPadding),
                            backgroundColor: Colors.blue[400],
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: skickaButtonFontSize,
                            ),
                            alignment: Alignment.bottomLeft,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            "Skicka",
                            style: TextStyle(
                                fontFamily: 'Roboto', color: Colors.white),
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
    );
  }
}
