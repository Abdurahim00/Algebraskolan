import 'package:flutter/foundation.dart';

import '../backend/question_service.dart';

class QuestionProvider with ChangeNotifier {
  Map<String, dynamic>? _question;
  final ValueNotifier<bool> showCorrectAnimation = ValueNotifier(false);
  final ValueNotifier<bool> showUncorrectAnimation = ValueNotifier(false);

  // Getter to access the current question outside the class
  Map<String, dynamic>? get question => _question;

  Future<void> fetchQuestion(int classNumber) async {
    try {
      _question = await getRandomQuestion(classNumber);
      notifyListeners(); // Notify only after successfully fetching the question
    } catch (e) {
      Exception('Error fetching question: $e');
      // Handle any error state as needed
      // Consider notifying listeners if the UI needs to react to this error state
    }
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
    // Do not call notifyListeners() here if you're using ValueNotifier for animations

    return isCorrect;
  }

  void resetAnimation() {
    showCorrectAnimation.value = false;
    showUncorrectAnimation.value = false;
    // Do not call notifyListeners() here if you're using ValueNotifier for animations
  }
}
