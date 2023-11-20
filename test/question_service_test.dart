import 'dart:math';

import 'package:algebra/backend/question_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRandom extends Mock implements Random {}

void main() {
  group('QuestionService', () {
    group('getQuestionsByClass', () {
      test('returns the correct data structure for an existent class number',
          () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore
            .collection('math_questions')
            .add({'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2});

        final questions = await getQuestionsByClass(1, firestore: firestore);

        expect(questions, [
          {'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2}
        ]);
      });

      test('returns an empty list for a non-existent class number', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final questions = await getQuestionsByClass(1, firestore: firestore);

        expect(questions, []);
      });
    });

    group('getRandomQuestion', () {
      test('returns a random question for an existent class number', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore
            .collection('math_questions')
            .add({'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2});

        final MockRandom random = MockRandom();

        when(() => random.nextInt(any(that: isA<int>()))).thenReturn(0);

        final question =
            await getRandomQuestion(1, random: random, firestore: firestore);

        expect(question,
            {'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2});
      });

      test('throws an exception for a non-existent class number', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        final MockRandom random = MockRandom();

        expect(
            () async => await getRandomQuestion(1,
                random: random, firestore: firestore),
            throwsException);
      });
    });

    group('checkAnswer', () {
      test('returns true for a correct answer', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore
            .collection('math_questions')
            .add({'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2});

        final isCorrect = await checkAnswer(1, 1, '2', firestore: firestore);

        expect(isCorrect, true);
      });

      test('returns false for an incorrect answer', () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

        await firestore
            .collection('math_questions')
            .add({'class': 1, 'index': 1, 'question': '1 + 1', 'answer': 2});

        final isCorrect = await checkAnswer(1, 1, '3', firestore: firestore);

        expect(isCorrect, false);
      });
    });
  });
}
