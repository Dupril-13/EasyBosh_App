
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/question_model.dart';

part 'quiz_session_provider.g.dart';

class QuizSessionState {
  final Map<int, Set<int>> answers;
  final int? quizId;

  QuizSessionState({this.answers = const {}, this.quizId});

  QuizSessionState copyWith({
    Map<int, Set<int>>? answers,
    int? quizId,
  }) {
    return QuizSessionState(
      answers: answers ?? this.answers,
      quizId: quizId ?? this.quizId,
    );
  }
}

@riverpod
class QuizSession extends _$QuizSession {
  @override
  QuizSessionState build() {
    return QuizSessionState();
  }

  void startQuiz(int quizId) {
    state = QuizSessionState(quizId: quizId, answers: {});
  }

  void selectAnswer(int questionId, int optionId, bool isMultipleChoice) {
    final newAnswers = Map<int, Set<int>>.from(state.answers);
    if (isMultipleChoice) {
      newAnswers.putIfAbsent(questionId, () => {});
      if (newAnswers[questionId]!.contains(optionId)) {
        newAnswers[questionId]!.remove(optionId);
      } else {
        newAnswers[questionId]!.add(optionId);
      }
    } else {
      newAnswers[questionId] = {optionId};
    }
    state = state.copyWith(answers: newAnswers);
  }

  Map<String, dynamic> submitQuiz(List<QuestionModel> questions) {
    int score = 0;
    List<Map<String, dynamic>> detailedQuestions = [];

    for (var question in questions) {
      final correctOptions = question.options.where((o) => o.estCorrecte).map((o) => o.id).toSet();
      final userOptions = state.answers[question.id] ?? {};

      bool isCorrect = correctOptions.length == userOptions.length && correctOptions.every((id) => userOptions.contains(id));
      if (isCorrect) {
        score++;
      }

      detailedQuestions.add({
        'questionText': question.texte,
        'userAnswer': userOptions.map((id) => question.options.firstWhere((o) => o.id == id).texte).join(', '),
        'correctAnswer': correctOptions.map((id) => question.options.firstWhere((o) => o.id == id).texte).join(', '),
        'isCorrect': isCorrect,
      });
    }

    return {
      'score': score,
      'totalQuestions': questions.length,
      'questions': detailedQuestions,
    };
  }
}

