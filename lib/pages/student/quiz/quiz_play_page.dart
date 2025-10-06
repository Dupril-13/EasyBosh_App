import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/quiz_model.dart';
import '../../../models/question_model.dart';
import '../../../providers/current_quiz_provider.dart';
import '../../../providers/quiz_session_provider.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final QuizModel quiz;

  const QuizPlayPage({super.key, required this.quiz});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  int _currentQuestionIndex = 0;
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _remainingSeconds = 0;
  bool _isInitialized = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQuiz();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _initQuiz() async {
    try {
      await ref.read(currentQuizProvider.notifier).loadQuiz(widget.quiz.id);
      await ref.read(quizSessionProvider.notifier).startSession(widget.quiz.id);

      final session = ref.read(quizSessionProvider).currentSession;
      if (widget.quiz.tempsLimite != null && session != null) {
        final totalSeconds = widget.quiz.tempsLimite! * 60;
        _remainingSeconds = totalSeconds - session.tempsPasse;

        if (_remainingSeconds > 0) {
          _startTimer();
        } else {
          _submitQuiz();
          return;
        }
      }

      _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        ref.read(quizSessionProvider.notifier).saveProgress();
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _remainingSeconds--;
      });

      ref.read(quizSessionProvider.notifier).incrementTime();

      if (_remainingSeconds <= 0) {
        _submitQuiz();
      }

      if (_remainingSeconds == 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Il vous reste 1 minute !'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();
    _autoSaveTimer?.cancel();

    try {
      final questions = ref.read(currentQuizProvider).shuffledQuestions;
      await ref.read(quizSessionProvider.notifier).submitQuiz(questions);

      final sessionState = ref.read(quizSessionProvider);

      if (sessionState.submittedSession != null && mounted) {
        context.go('/quiz_results', extra: {
          'session': sessionState.submittedSession!,
          'quiz': widget.quiz,
          'questions': questions,
          'userAnswers': sessionState.userAnswers,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Soumettre le quiz ?'),
          content: const Text(
            'Êtes-vous sûr de vouloir soumettre vos réponses ? '
                'Vous ne pourrez plus les modifier.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitQuiz();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Soumettre'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuizState = ref.watch(currentQuizProvider);
    final sessionState = ref.watch(quizSessionProvider);

    if (!_isInitialized || currentQuizState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement du quiz...'),
            ],
          ),
        ),
      );
    }

    if (currentQuizState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(currentQuizState.errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = currentQuizState.shuffledQuestions;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Aucune question disponible')),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Quitter le quiz ?'),
              content: const Text(
                'Votre progression sera sauvegardée automatiquement.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Quitter'),
                ),
              ],
            );
          },
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(questions.length),
        body: Column(
          children: [
            _buildProgressBar(questions.length),
            if (widget.quiz.tempsLimite != null) _buildTimer(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildQuestionCard(currentQuestion, sessionState),
              ),
            ),
            _buildNavigationButtons(questions.length),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int totalQuestions) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
        onPressed: () async {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Quitter le quiz ?'),
                content: const Text('Votre progression sera sauvegardée.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Quitter'),
                  ),
                ],
              );
            },
          );
          if (shouldPop == true && mounted) {
            context.pop();
          }
        },
      ),
      title: Text(
        'Question ${_currentQuestionIndex + 1}/$totalQuestions',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_currentQuestionIndex + 1)}/$totalQuestions',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final isUrgent = _remainingSeconds <= 60;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            color: isUrgent ? Colors.red.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Temps restant: $timeString',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red.shade700 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      QuestionModel question,
      QuizSessionState sessionState,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.texte,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${question.points} ${question.points > 1 ? "points" : "point"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildAnswerOptions(question, sessionState),
            if (widget.quiz.feedbackImmediat &&
                sessionState.userAnswers.containsKey(question.id.toString()))
              _buildImmediateFeedback(question, sessionState),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(
      QuestionModel question,
      QuizSessionState sessionState,
      ) {
    final currentAnswer = sessionState.userAnswers[question.id.toString()];

    switch (question.type) {
      case QuestionType.qcmUnique:
      case QuestionType.vraiFaux:
        return _buildSingleChoiceOptions(question, currentAnswer);

      case QuestionType.qcmMultiple:
        return _buildMultipleChoiceOptions(question, currentAnswer);

      default:
        return const Text('Type de question non supporté');
    }
  }

  Widget _buildSingleChoiceOptions(
      QuestionModel question,
      dynamic currentAnswer,
      ) {
    return Column(
      children: question.options.map((option) {
        final isSelected = currentAnswer == option.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              ref.read(quizSessionProvider.notifier).updateAnswer(
                question.id,
                option.id,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.texte,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.black87 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions(
      QuestionModel question,
      dynamic currentAnswer,
      ) {
    final selectedIds = currentAnswer is List
        ? Set<int>.from(currentAnswer.map((e) => e as int))
        : <int>{};

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
    children: [
    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
    const SizedBox(width: 8),
    Expanded(
    child: Text(
    'Plusieurs réponses possibles',
    style: TextStyle(
    fontSize: 13,
    color: Colors.blue.shade700,
    fontWeight: FontWeight.w500,
    ),
    ),
    ),
    ],
    ),
    ),
          const SizedBox(height: 12),
          ...question.options.map((option) {
            final isSelected = selectedIds.contains(option.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  final newSelectedIds = Set<int>.from(selectedIds);
                  if (isSelected) {
                    newSelectedIds.remove(option.id);
                  } else {
                    newSelectedIds.add(option.id);
                  }
                  ref.read(quizSessionProvider.notifier).updateAnswer(
                    question.id,
                    newSelectedIds.toList(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.texte,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? Colors.black87 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
    );
  }

  Widget _buildImmediateFeedback(
      QuestionModel question,
      QuizSessionState sessionState,
      ) {
    final userAnswer = sessionState.userAnswers[question.id.toString()];
    final correctOptionIds = question.options
        .where((opt) => opt.estCorrecte)
        .map((opt) => opt.id)
        .toSet();

    bool isCorrect = false;
    if (question.type == QuestionType.qcmUnique ||
        question.type == QuestionType.vraiFaux) {
      isCorrect = correctOptionIds.contains(userAnswer);
    } else if (question.type == QuestionType.qcmMultiple &&
        userAnswer is List) {
      final userSet = Set<int>.from(userAnswer.map((e) => e as int));
      isCorrect = userSet.length == correctOptionIds.length &&
          userSet.containsAll(correctOptionIds);
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Bonne réponse !' : 'Réponse incorrecte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color:
                  isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (question.explication != null) ...[
            const SizedBox(height: 8),
            Text(
              question.explication!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(int totalQuestions) {
    final isLastQuestion = _currentQuestionIndex == totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Précédent',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                if (isLastQuestion) {
                  _showSubmitConfirmation();
                } else {
                  setState(() {
                    _currentQuestionIndex++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                isLastQuestion ? 'Soumettre' : 'Suivant',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}