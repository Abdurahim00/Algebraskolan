import 'dart:async';
import 'package:algebra/page/studentPage/student_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../provider/question_provider.dart';

class QuestionsScreen extends StatefulWidget {
  final int classNumber;

  const QuestionsScreen({required this.classNumber, super.key});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      Provider.of<QuestionProvider>(context, listen: false)
          .fetchQuestion(widget.classNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, _) {
        if (questionProvider.question == null) {
          return Center(
              child: Lottie.asset("assets/images/Circle Loading.json",
                  width: screenWidth * 0.2));
        }

        return Scaffold(
          backgroundColor: Colors.grey[300],
          body: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade500,
                              offset: const Offset(4.0, 4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-4.0, -4.0),
                              blurRadius: 20.0,
                              spreadRadius: 1.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "${questionProvider.question!['question']}",
                              style: const TextStyle(
                                fontFamily:
                                    'Pangolin', // Use the font family name you declared in pubspec.yaml
                                fontSize: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.45,
                            height: MediaQuery.of(context).size.height * 0.1,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade500,
                                  offset: const Offset(4.0, 4.0),
                                  blurRadius: 15.0,
                                  spreadRadius: 1.0,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-4.0, -4.0),
                                  blurRadius: 20.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    controller: _textController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[300],
                                      hintText: "Svara",
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                        right:
                                            40, // Adjust the padding to ensure text doesn't overlap with the button
                                      ),
                                    ),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter
                                          .digitsOnly, // Only numbers can be entered
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.orangeAccent,
                                    ),
                                    onPressed: () {
                                      _textController.clear();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.height * 0.06,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade500,
                                  offset: const Offset(4.0, 4.0),
                                  blurRadius: 15.0,
                                  spreadRadius: 1.0,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-4.0, -4.0),
                                  blurRadius: 20.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () async {
                                if (_textController.text.isNotEmpty) {
                                  bool isCorrect =
                                      await questionProvider.validateAnswer(
                                          widget.classNumber,
                                          questionProvider.question!['index'],
                                          _textController.text);

                                  _textController.clear();

                                  if (isCorrect) {
                                    // Start a timer to reset the animation after a delay
                                    Timer(const Duration(milliseconds: 1000),
                                        () {
                                      questionProvider.resetAnimation();

                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              const StudentScreen(),

                                          transitionDuration:
                                              const Duration(milliseconds: 500),
                                          // Adjust as needed
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            // For fade transition
                                            var fadeTween = Tween(
                                                    begin: 0.0, end: 1.0)
                                                .chain(CurveTween(
                                                    curve: Curves.easeInOut));
                                            var fadeAnimation =
                                                animation.drive(fadeTween);

                                            return FadeTransition(
                                                opacity: fadeAnimation,
                                                child: child);
                                          },
                                        ),
                                      );
                                    });
                                  } else {
                                    // Start a timer to reset the animation after a delay
                                    Timer(const Duration(milliseconds: 1100),
                                        () {
                                      questionProvider.resetAnimation();
                                    });
                                  }
                                } else {
                                  print("No input provided");
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (questionProvider.showCorrectAnimation.value)
                Positioned(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.3,
                        heightFactor: 0.3,
                        alignment: Alignment.center,
                        child: Lottie.asset("assets/images/achievement.json"),
                      ),
                    ),
                  ),
                ),
              if (questionProvider.showUncorrectAnimation.value)
                Positioned(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.3,
                        heightFactor: 0.3,
                        alignment: Alignment.center,
                        child: Lottie.asset("assets/images/canceled.json"),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
