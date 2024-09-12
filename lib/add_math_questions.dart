import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class MathQuestionsAdditionService {
  // Initialize Firebase in case it hasn't been initialized
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print("Firebase initialized in MathQuestionsAdditionService.");
    } catch (e) {
      print("Firebase already initialized or error: $e");
    }
  }

  // Function to add 50 math questions to each class from 0 to 9
  static Future<void> addMathQuestionsToAllClasses() async {
    await initializeFirebase(); // Ensure Firebase is initialized

    final CollectionReference mathQuestionsCollection =
        FirebaseFirestore.instance.collection('math_questions');

    try {
      // Define the class numbers (0 to 9)
      List<int> classNumbers = List<int>.generate(10, (index) => index);

      for (int classNumber in classNumbers) {
        print('Adding questions to class $classNumber');
        List<Map<String, dynamic>> questions =
            _generateMathQuestions(classNumber);

        for (Map<String, dynamic> question in questions) {
          // Add question to Firestore
          await mathQuestionsCollection.add(question);
          print('Added question: ${question['question']} to class $classNumber');
        }
      }

      print('50 questions added to each class successfully.');
    } catch (e) {
      print('Error adding math questions: $e');
    }
  }

  // Generates 50 math questions for a given class
  static List<Map<String, dynamic>> _generateMathQuestions(int classNumber) {
    List<Map<String, dynamic>> questions = [];
    Random random = Random();

    for (int i = 0; i < 50; i++) {
      int num1 = random.nextInt(10) + 1; // Generates a number between 1 and 10
      int num2 = random.nextInt(10) + 1;

      bool isAddition = random.nextBool(); // Randomly choose addition or subtraction

      String questionText = isAddition 
          ? 'Vad är $num1 + $num2?' 
          : 'Vad är $num1 - $num2?';

      int answer = isAddition ? num1 + num2 : num1 - num2;

      // Ensure no negative answers for subtraction
      if (!isAddition && answer < 0) {
        i--; // Skip this iteration and do not count it towards the 50
        continue;
      }

      questions.add({
        'question': questionText,
        'answer': answer,
        'class': classNumber,
        'index': i, // Using i as the index for each question
      });
    }

    return questions;
  }
}
