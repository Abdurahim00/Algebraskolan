import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure to import this

import '../backend/question_service.dart';

class QuestionProvider with ChangeNotifier {
  Map<String, dynamic>? question;
  final ValueNotifier<bool> showCorrectAnimation = ValueNotifier(false);
  final ValueNotifier<bool> showUncorrectAnimation = ValueNotifier(false);

  Future<void> fetchQuestion(int classNumber) async {
    question = await getRandomQuestion(classNumber);
    notifyListeners();
  }

  Future<bool> validateAnswer(
      int classNumber, int questionIndex, String answer) async {
    bool isCorrect = await checkAnswer(classNumber, questionIndex, answer);
    if (isCorrect) {
      showCorrectAnimation.value = true;
      showUncorrectAnimation.value = false;
    } else {
      showCorrectAnimation.value = false;
      showUncorrectAnimation.value = true;
    }
    notifyListeners();
    return isCorrect;
  }

  void resetAnimation() {
    showCorrectAnimation.value = false;
    showUncorrectAnimation.value = false;
    notifyListeners();
  }

  // New method to reset hasAnsweredQuestionCorrectly field
  Future<void> resetHasAnswered(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'hasAnsweredQuestionCorrectly': false,
    });
  }
}
