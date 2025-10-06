import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/option_reponse_model.dart';
import '../services/quiz_service.dart';

class CurrentQuizState {
  final QuizModel? quiz;
  final List<QuestionModel> questions;
  final List<QuestionModel> shuffledQuestions;
  final bool isLoading;
  final String? errorMessage;

  CurrentQuizState({
    this.quiz,
    this.questions = const [],
    this.shuffledQuestions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CurrentQuizState copyWith({
    QuizModel? quiz,
    List<QuestionModel>? questions,
    List<QuestionModel>? shuffledQuestions,
    bool? isLoading,
    String? errorMessage,
    bool resetError = false,
  }) {
    return CurrentQuizState(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      shuffledQuestions: shuffledQuestions ?? this.shuffledQuestions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CurrentQuizNotifier extends StateNotifier<CurrentQuizState> {
  final QuizService _quizService = QuizService();

  CurrentQuizNotifier() : super(CurrentQuizState());

  Future<void> loadQuiz(int quizId) async {
    state = state.copyWith(isLoading: true, resetError: true);
    try {
      final quiz = await _quizService.fetchQuizById(quizId);
      final questions = await _quizService.fetchQuestionsWithOptions(quizId);

      List<QuestionModel> questionsToUse = List.from(questions);
      if (quiz.melangerQuestions) {
        questionsToUse.shuffle();
      }

      if (quiz.melangerReponses) {
        questionsToUse = questionsToUse.map((question) {
          final shuffledOptions = List<dynamic>.from(question.options)
            ..shuffle();
          return question.copyWith(
            options: shuffledOptions.cast<OptionReponseModel>(),
          );
        }).toList();
      }

      state = state.copyWith(
        quiz: quiz,
        questions: questions,
        shuffledQuestions: questionsToUse,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = CurrentQuizState();
  }
}

final currentQuizProvider =
StateNotifierProvider<CurrentQuizNotifier, CurrentQuizState>(
      (ref) => CurrentQuizNotifier(),
);