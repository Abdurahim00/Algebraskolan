import 'package:algebra/backend/control_page.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/question_provider.dart';
import 'package:algebra/provider/student_provider.dart'; // make sure to import this
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signOut(); // force sign-out for testing

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(const MyApp());
  });
}
/*
Future<void> addQuestionsToFirestore() async {
  // List of questions
  List<Map<String, dynamic>> questions = [
    // Add your questions here in this format
    {"index": 4, "question": "Vad är 1 + 3?", "answer": 4, "class": "0"},
    {"index": 5, "question": "Vad är 6 - 4?", "answer": 2, "class": "0"},
    {"index": 6, "question": "Vad är 4 + 10?", "answer": 14, "class": "0"},
    {"index": 7, "question": "Vad är 8 - 4?", "answer": 4, "class": "0"},
    {"index": 8, "question": "Vad är 9 + 1?", "answer": 10, "class": "0"},
    {"index": 9, "question": "Vad är 10 + 2?", "answer": 12, "class": "0"},
    {"index": 10, "question": "Vad är 2 - 2?", "answer": 0, "class": "0"},

    {"index": 1, "question": "Vad är 1 + 3?", "answer": 4, "class": "1"},
    {"index": 2, "question": "Vad är 6 - 4?", "answer": 2, "class": "1"},
    {"index": 3, "question": "Vad är 4 + 10?", "answer": 14, "class": "1"},
    {"index": 4, "question": "Vad är 8 - 4?", "answer": 4, "class": "1"},
    {"index": 5, "question": "Vad är 9 + 1?", "answer": 10, "class": "1"},
    {"index": 6, "question": "Vad är 10 + 2?", "answer": 12, "class": "1"},
    {"index": 7, "question": "Vad är 2 - 2?", "answer": 0, "class": "1"},
    {"index": 8, "question": "Vad är 9 + 1?", "answer": 10, "class": "1"},
    {"index": 9, "question": "Vad är 10 + 2?", "answer": 12, "class": "1"},
    {"index": 10, "question": "Vad är 2 - 2?", "answer": 0, "class": "1"},

    {"index": 1, "question": "Vad är 10 + 3?", "answer": 13, "class": "2"},
    {"index": 2, "question": "Vad är 16 - 4?", "answer": 12, "class": "2"},
    {"index": 3, "question": "Vad är 14 + 10?", "answer": 24, "class": "2"},
    {"index": 4, "question": "Vad är 18 - 4?", "answer": 14, "class": "2"},
    {"index": 5, "question": "Vad är 19 + 1?", "answer": 20, "class": "2"},
    {"index": 6, "question": "Vad är 10 + 2?", "answer": 12, "class": "2"},
    {"index": 7, "question": "Vad är 20 - 2?", "answer": 18, "class": "2"},
    {"index": 8, "question": "Vad är 29 + 1?", "answer": 30, "class": "2"},
    {"index": 9, "question": "Vad är 11 + 2?", "answer": 13, "class": "2"},
    {"index": 10, "question": "Vad är 20 - 2?", "answer": 18, "class": "2"},

    {"index": 1, "question": "Vad är 14 + 3?", "answer": 17, "class": "3"},
    {"index": 2, "question": "Vad är 16 - 4?", "answer": 12, "class": "3"},
    {"index": 3, "question": "Vad är 24 + 10?", "answer": 34, "class": "3"},
    {"index": 4, "question": "Vad är 48 - 4?", "answer": 44, "class": "3"},
    {"index": 5, "question": "Vad är 29 + 1?", "answer": 30, "class": "3"},
    {"index": 6, "question": "Vad är 100 + 2?", "answer": 102, "class": "3"},
    {"index": 7, "question": "Vad är 200 - 2?", "answer": 198, "class": "3"},
    {"index": 8, "question": "Vad är 49 + 4?", "answer": 53, "class": "3"},
    {"index": 9, "question": "Vad är 120 + 2?", "answer": 122, "class": "3"},
    {"index": 10, "question": "Vad är 24 - 2?", "answer": 22, "class": "3"},

    {"index": 1, "question": "Vad är 14 - 3?", "answer": 11, "class": "4"},
    {"index": 2, "question": "Vad är 60 - 4?", "answer": 56, "class": "4"},
    {"index": 3, "question": "Vad är 42 + 10?", "answer": 52, "class": "4"},
    {"index": 4, "question": "Vad är 83 - 4?", "answer": 79, "class": "4"},
    {"index": 5, "question": "Vad är 90 + 1?", "answer": 91, "class": "4"},
    {"index": 6, "question": "Vad är 13 + 2 -3?", "answer": 12, "class": "4"},
    {"index": 7, "question": "Vad är 200 - 198?", "answer": 2, "class": "4"},
    {"index": 8, "question": "Vad är 90 + 21?", "answer": 111, "class": "4"},
    {"index": 9, "question": "Vad är 103 + 2?", "answer": 105, "class": "4"},
    {"index": 10, "question": "Vad är 22 - 20?", "answer": 2, "class": "4"},

    {"index": 1, "question": "Vad är 1 x 3?", "answer": 3, "class": "5"},
    {"index": 2, "question": "Vad är 6 x 4?", "answer": 24, "class": "5"},
    {"index": 3, "question": "Vad är 4 x 10?", "answer": 40, "class": "5"},
    {"index": 4, "question": "Vad är 8 / 4?", "answer": 2, "class": "5"},
    {"index": 5, "question": "Vad är 900 + 200?", "answer": 1100, "class": "5"},
    {"index": 6, "question": "Vad är 102 + 22?", "answer": 124, "class": "5"},
    {"index": 7, "question": "Vad är 2 x 6?", "answer": 12, "class": "5"},
    {"index": 8, "question": "Vad är 9 x 3?", "answer": 27, "class": "5"},
    {"index": 9, "question": "Vad är 10/2?", "answer": 5, "class": "5"},
    {"index": 10, "question": "Vad är 2000/2?", "answer": 1000, "class": "5"},

    {"index": 1, "question": "Vad är 53 + 53?", "answer": 106, "class": "6"},
    {"index": 2, "question": "Vad är 62 - 42?", "answer": 20, "class": "6"},
    {"index": 3, "question": "Vad är 42 / 2?", "answer": 21, "class": "6"},
    {"index": 4, "question": "Vad är 83 - 44?", "answer": 127, "class": "6"},
    {"index": 5, "question": "Vad är 92 + 12?", "answer": 104, "class": "6"},
    {
      "index": 6,
      "question": "Vad är 103 - (2x2) ?",
      "answer": 99,
      "class": "6"
    },
    {"index": 7, "question": "Vad är 23 x 2?", "answer": 46, "class": "6"},
    {"index": 8, "question": "Vad är 92 + 18?", "answer": 110, "class": "6"},
    {"index": 9, "question": "Vad är (10/2)+2?", "answer": 7, "class": "6"},
    {"index": 10, "question": "Vad är 233 - 34?", "answer": 199, "class": "6"},

    {"index": 1, "question": "Vad är 107 + 69?", "answer": 176, "class": "7"},
    {"index": 2, "question": "Vad är 60 x 3?", "answer": 18, "class": "7"},
    {"index": 3, "question": "Vad är 7 x 9?", "answer": 63, "class": "7"},
    {"index": 4, "question": "Vad är 120 / 4?", "answer": 30, "class": "7"},
    {"index": 5, "question": "Vad är 15 x 3?", "answer": 45, "class": "7"},
    {"index": 6, "question": "Vad är 120 + 45?", "answer": 165, "class": "7"},
    {"index": 7, "question": "Vad är 180 / 3?", "answer": 60, "class": "7"},
    {"index": 8, "question": "Vad är 100 x 8?", "answer": 800, "class": "7"},
    {"index": 9, "question": "Vad är 1000 / 2?", "answer": 500, "class": "7"},
    {"index": 10, "question": "Vad är 982 - 83?", "answer": 899, "class": "7"},

    {"index": 1, "question": "Vad är 44 x 2?", "answer": 88, "class": "8"},
    {"index": 2, "question": "Vad är 9 x 20?", "answer": 180, "class": "8"},
    {"index": 3, "question": "Lös ut x. x + 3 = 5?", "answer": 2, "class": "8"},
    {"index": 4, "question": "Vad är 150 / 3?", "answer": 50, "class": "8"},
    {"index": 5, "question": "Vad är 99 / 9?", "answer": 11, "class": "8"},
    {"index": 6, "question": "Vad är 201 + 42?", "answer": 243, "class": "8"},
    {
      "index": 7,
      "question": "Lös ut x. x + 50 = 58?",
      "answer": 8,
      "class": "8"
    },
    {"index": 8, "question": "Vad är 90 / 30?", "answer": 3, "class": "8"},
    {"index": 9, "question": "Vad är 10 + 295?", "answer": 305, "class": "8"},
    {"index": 10, "question": "Vad är 28 / 7?", "answer": 4, "class": "8"},

    {"index": 1, "question": "Vad är 1322 + 32?", "answer": 1354, "class": "9"},
    {
      "index": 2,
      "question": "Lös ut x. 2x + 10 = 110",
      "answer": 50,
      "class": "9"
    },
    {
      "index": 3,
      "question": "Vad är 43 + 10 - 23?",
      "answer": 14,
      "class": "9"
    },
    {
      "index": 4,
      "question": "Lös ut x. 5x + 10 = 20",
      "answer": 2,
      "class": "9"
    },
    {"index": 5, "question": "Vad är 99 x 2?", "answer": 188, "class": "9"},
    {
      "index": 6,
      "question": "Lös ut x. x + 15 = 25?",
      "answer": 10,
      "class": "9"
    },
    {
      "index": 7,
      "question": "Vad är 2 - 2 + 40 - 2?",
      "answer": 38,
      "class": "9"
    },
    {
      "index": 8,
      "question": "Vad är 9 + (12 x 3) ?",
      "answer": 45,
      "class": "9"
    },
    {
      "index": 9,
      "question": "Lös ut x. 10x + 1000 = 1100?",
      "answer": 10,
      "class": "9"
    },
    {
      "index": 10,
      "question": "Vad är 30 - (22/2) + 50 ?",
      "answer": 69,
      "class": "9"
    },

    // ...
  ];

  // Get a reference to the Firestore instance
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to the 'questions' collection
  CollectionReference questionsRef = firestore.collection('math_questions');

  // Iterate oVer the list of questions
  for (var question in questions) {
    // Add each question to Firestore
    await questionsRef.add(question);
  }
  print("Questions added to Firestore successfully");
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GoogleSignInProvider()),
        ChangeNotifierProvider(create: (context) => StudentProvider()),
        ChangeNotifierProvider(create: (context) => QuestionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}
