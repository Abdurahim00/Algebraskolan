import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getQuestionsByClass(int classNumber) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to the 'questions' collection
  CollectionReference questionsRef = firestore.collection('math_questions');

  // Fetch questions for the given class
  QuerySnapshot querySnapshot =
      await questionsRef.where('class', isEqualTo: classNumber).get();

  // Map each DocumentSnapshot to its data, cast as Map<String, dynamic>
  return querySnapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();
}

Future<Map<String, dynamic>> getRandomQuestion(int classNumber) async {
  // Fetch all questions for the class
  List<Map<String, dynamic>> questions = await getQuestionsByClass(classNumber);

  if (questions.isNotEmpty) {
    // Get a random question
    var random = Random();
    int randomIndex = random.nextInt(questions.length);

    return questions[randomIndex];
  } else {
    throw Exception('No questions found for class $classNumber');
  }
}

Future<bool> checkAnswer(
    int classNumber, int questionIndex, String userAnswer) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to the 'questions' collection
  CollectionReference questionsRef = firestore.collection('math_questions');

  // Fetch question with the given class and index
  DocumentSnapshot docSnapshot = await questionsRef
      .where('class', isEqualTo: classNumber)
      .where('index', isEqualTo: questionIndex)
      .get()
      .then((snapshot) =>
          snapshot.docs.first); // Get the first document matching the query

  // Get question data
  Map<String, dynamic> questionData =
      docSnapshot.data() as Map<String, dynamic>;

  var userAnswerNum = num.tryParse(userAnswer);

  // Compare user answer to the correct answer
  if (questionData['answer'] == userAnswerNum) {
    return true;
  } else {
    return false;
  }
}
