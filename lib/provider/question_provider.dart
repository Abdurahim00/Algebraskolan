import 'package:flutter/foundation.dart';

import '../backend/question_service.dart';

class QuestionProvider with ChangeNotifier {
  Map<String, dynamic>? question;
  final ValueNotifier<bool> showCorrectAnimation = ValueNotifier(false);
  final ValueNotifier<bool> showUncorrectAnimation = ValueNotifier(false);
  bool isLoading = false; // Add a loading state

  Future<void> fetchQuestion(int classNumber) async {
    isLoading = true; // Set loading to true
    notifyListeners(); // Notify here to show a loading indicator

    question = await getRandomQuestion(classNumber);

    isLoading = false; // Reset loading state
    notifyListeners(); // Notify again to update UI with the fetched question
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
