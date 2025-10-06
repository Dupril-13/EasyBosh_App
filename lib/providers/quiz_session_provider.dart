import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_session_model.dart';
import '../models/question_model.dart';
import '../services/quiz_session_service.dart';

class QuizSessionState {
  final QuizSessionModel? currentSession;
  final Map<String, dynamic> userAnswers;
  final int elapsedSeconds;
  final bool isSubmitting;
  final QuizSessionModel? submittedSession;
  final String? errorMessage;

  QuizSessionState({
    this.currentSession,
    this.userAnswers = const {},
    this.elapsedSeconds = 0,
    this.isSubmitting = false,
    this.submittedSession,
    this.errorMessage,
  });

  QuizSessionState copyWith({
    QuizSessionModel? currentSession,
    Map<String, dynamic>? userAnswers,
    int? elapsedSeconds,
    bool? isSubmitting,
    QuizSessionModel? submittedSession,
    String? errorMessage,
    bool resetError = false,
    bool clearSubmitted = false,
  }) {
    return QuizSessionState(
      currentSession: currentSession ?? this.currentSession,
      userAnswers: userAnswers ?? this.userAnswers,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedSession:
      clearSubmitted ? null : (submittedSession ?? this.submittedSession),
      errorMessage: resetError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  final QuizSessionService _sessionService = QuizSessionService();

  QuizSessionNotifier() : super(QuizSessionState());

  Future<void> startSession(int quizId) async {
    try {
      final ongoingSession = await _sessionService.fetchOngoingSession(quizId);

      if (ongoingSession != null) {
        state = state.copyWith(
          currentSession: ongoingSession,
          userAnswers:
          Map<String, dynamic>.from(ongoingSession.reponsesUtilisateur),
          elapsedSeconds: ongoingSession.tempsPasse,
          resetError: true,
        );
      } else {
        final newSession = await _sessionService.createSession(quizId);
        state = state.copyWith(
          currentSession: newSession,
          userAnswers: {},
          elapsedSeconds: 0,
          resetError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void updateAnswer(int questionId, dynamic answer) {
    final updatedAnswers = Map<String, dynamic>.from(state.userAnswers);
    updatedAnswers[questionId.toString()] = answer;
    state = state.copyWith(userAnswers: updatedAnswers);
  }

  void incrementTime() {
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
  }

  Future<void> saveProgress() async {
    if (state.currentSession == null) return;

    try {
      await _sessionService.saveProgress(
        state.currentSession!.id,
        state.userAnswers,
        state.elapsedSeconds,
      );
    } catch (e) {
      print('Erreur auto-save: $e');
    }
  }

  Future<void> submitQuiz(List<QuestionModel> questions) async {
    if (state.currentSession == null) {
      state = state.copyWith(errorMessage: 'Aucune session active');
      return;
    }

    state = state.copyWith(isSubmitting: true, resetError: true);

    try {
      final submittedSession = await _sessionService.submitSession(
        state.currentSession!.id,
        state.userAnswers,
        state.elapsedSeconds,
        questions,
      );

      state = state.copyWith(
        isSubmitting: false,
        submittedSession: submittedSession,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = QuizSessionState();
  }
}

final quizSessionProvider =
StateNotifierProvider<QuizSessionNotifier, QuizSessionState>(
      (ref) => QuizSessionNotifier(),
);