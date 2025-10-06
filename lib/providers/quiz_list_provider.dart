import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

class QuizListState {
  final List<QuizModel> quizzes;
  final bool isLoading;
  final String? errorMessage;

  QuizListState({
    this.quizzes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  QuizListState copyWith({
    List<QuizModel>? quizzes,
    bool? isLoading,
    String? errorMessage,
    bool resetError = false,
  }) {
    return QuizListState(
      quizzes: quizzes ?? this.quizzes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QuizListNotifier extends StateNotifier<QuizListState> {
  final QuizService _quizService = QuizService();

  String? _lastNiveauCode;
  String? _lastSerieCode;
  int? _lastMatiereId;
  int? _lastChapitreId;

  QuizListNotifier() : super(QuizListState());

  Future<void> fetchQuizzes({
    String? niveauCode,
    String? serieCode,
    int? matiereId,
    int? chapitreId,
  }) async {
    _lastNiveauCode = niveauCode;
    _lastSerieCode = serieCode;
    _lastMatiereId = matiereId;
    _lastChapitreId = chapitreId;

    state = state.copyWith(isLoading: true, resetError: true);
    try {
      final quizzes = await _quizService.fetchQuizForStudent(
        niveauCode: niveauCode,
        serieCode: serieCode,
        matiereId: matiereId,
        chapitreId: chapitreId,
      );
      state = state.copyWith(quizzes: quizzes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await fetchQuizzes(
      niveauCode: _lastNiveauCode,
      serieCode: _lastSerieCode,
      matiereId: _lastMatiereId,
      chapitreId: _lastChapitreId,
    );
  }

  void reset() {
    state = QuizListState();
    _lastNiveauCode = null;
    _lastSerieCode = null;
    _lastMatiereId = null;
    _lastChapitreId = null;
  }
}

final quizListProvider =
StateNotifierProvider<QuizListNotifier, QuizListState>(
      (ref) => QuizListNotifier(),
);