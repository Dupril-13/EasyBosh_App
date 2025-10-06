import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/quiz_model.dart';
import '../../../models/question_model.dart';
import '../../../providers/current_quiz_provider.dart';
import '../../../providers/quiz_session_provider.dart';

class QuizSessionPage extends ConsumerStatefulWidget {
  final QuizModel quiz;

  const QuizSessionPage({super.key, required this.quiz});

  @override
  ConsumerState<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends ConsumerState<QuizSessionPage> {
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      ref.read(quizSessionProvider.notifier).incrementTime();

      if (widget.quiz.tempsLimite != null) {
        final elapsed = ref.read(quizSessionProvider).elapsedSeconds;
        final limit = widget.quiz.tempsLimite! * 60;

        if (elapsed >= limit) {
          _timer?.cancel();
          _autoSubmitQuiz();
        }
      }
    });

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      ref.read(quizSessionProvider.notifier).saveProgress();
    });
  }

  Future<void> _autoSubmitQuiz() async {
    final quizState = ref.read(currentQuizProvider);
    await ref
        .read(quizSessionProvider.notifier)
        .submitQuiz(quizState.shuffledQuestions);

    if (mounted) {
      _showTimeUpDialog();
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Temps écoulé'),
        content: const Text(
            'Le temps imparti pour ce quiz est écoulé. Vos réponses ont été automatiquement soumises.'),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/quiz_results');
            },
            child: const Text('Voir les résultats'),
          ),
        ],
      ),
    );
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextQuestion() {
    final quizState = ref.read(currentQuizProvider);
    if (_currentQuestionIndex < quizState.shuffledQuestions.length - 1) {
      _goToQuestion(_currentQuestionIndex + 1);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _goToQuestion(_currentQuestionIndex - 1);
    }
  }

  Future<void> _submitQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soumettre le quiz'),
        content: const Text(
            'Êtes-vous sûr de vouloir soumettre vos réponses ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final quizState = ref.read(currentQuizProvider);
      await ref
          .read(quizSessionProvider.notifier)
          .submitQuiz(quizState.shuffledQuestions);

      final sessionState = ref.read(quizSessionProvider);

      if (mounted) {
        if (sessionState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sessionState.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          context.go('/quiz_results');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(currentQuizProvider);
    final sessionState = ref.watch(quizSessionProvider);

    if (quizState.shuffledQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter le quiz'),
            content: const Text(
                'Votre progression sera sauvegardée. Voulez-vous vraiment quitter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(quizSessionProvider.notifier).saveProgress();
                  Navigator.pop(context, true);
                },
                child: const Text('Quitter'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Quitter le quiz'),
                  content: const Text(
                      'Votre progression sera sauvegardée. Voulez-vous vraiment quitter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(quizSessionProvider.notifier).saveProgress();
                        Navigator.pop(context, true);
                      },
                      child: const Text('Quitter'),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            widget.quiz.nom,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            _buildTimerWidget(sessionState.elapsedSeconds),
          ],
        ),
        body: Column(
          children: [
            _buildProgressBar(quizState.shuffledQuestions.length),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizState.shuffledQuestions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildQuestionCard(
                    quizState.shuffledQuestions[index],
                    index,
                    sessionState,
                  );
                },
              ),
            ),
            _buildNavigationButtons(quizState.shuffledQuestions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerWidget(int elapsedSeconds) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor = Colors.green;
    if (widget.quiz.tempsLimite != null) {
      final limit = widget.quiz.tempsLimite! * 60;
      final remaining = limit - elapsedSeconds;
      if (remaining < 60) {
        timerColor = Colors.red;
      } else if (remaining < 300) {
        timerColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: timerColor),
          const SizedBox(width: 4),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} sur $totalQuestions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      QuestionModel question,
      int index,
      QuizSessionState sessionState,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Question ${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${question.points} pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                question.texte,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              if (question.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      question.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildAnswerWidget(question, sessionState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(
      QuestionModel question,
      QuizSessionState sessionState,
      ) {
    final currentAnswer = sessionState.userAnswers[question.id.toString()];

    switch (question.type) {
      case QuestionType.qcmUnique:
        return _buildQCMUniqueWidget(question, currentAnswer);

      case QuestionType.qcmMultiple:
        return _buildQCMMultipleWidget(question, currentAnswer);

      case QuestionType.vraiFaux:
        return _buildVraiFauxWidget(question, currentAnswer);

      case QuestionType.texteLibre:
        return _buildTexteLibreWidget(question, currentAnswer);

      case QuestionType.numerique:
        return _buildNumeriqueWidget(question, currentAnswer);

      case QuestionType.association:
        return _buildAssociationWidget(question, currentAnswer);

      default:
        return const Text('Type de question non supporté');
    }
  }

  Widget _buildQCMUniqueWidget(QuestionModel question, dynamic currentAnswer) {
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
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.texte,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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

  Widget _buildQCMMultipleWidget(QuestionModel question, dynamic currentAnswer) {
    final selectedIds = currentAnswer is List
        ? List<int>.from(currentAnswer)
        : <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plusieurs réponses possibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...question.options.map((option) {
          final isSelected = selectedIds.contains(option.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                final newSelectedIds = List<int>.from(selectedIds);
                if (isSelected) {
                  newSelectedIds.remove(option.id);
                } else {
                  newSelectedIds.add(option.id);
                }
                ref.read(quizSessionProvider.notifier).updateAnswer(
                  question.id,
                  newSelectedIds,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.texte,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
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

  Widget _buildVraiFauxWidget(QuestionModel question, dynamic currentAnswer) {
    return Row(
      children: [
        Expanded(
          child: _buildVraiFauxOption(
            question.id,
            'Vrai',
            true,
            currentAnswer == true,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVraiFauxOption(
            question.id,
            'Faux',
            false,
            currentAnswer == false,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildVraiFauxOption(
      int questionId,
      String label,
      bool value,
      bool isSelected,
      Color color,
      ) {
    return InkWell(
      onTap: () {
        ref.read(quizSessionProvider.notifier).updateAnswer(
          questionId,
          value,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              size: 40,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTexteLibreWidget(QuestionModel question, dynamic currentAnswer) {
    final controller = TextEditingController(
      text: currentAnswer?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Saisissez votre réponse ici...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) {
        ref.read(quizSessionProvider.notifier).updateAnswer(
          question.id,
          value,
        );
      },
    );
  }

  Widget _buildNumeriqueWidget(QuestionModel question, dynamic currentAnswer) {
    final controller = TextEditingController(
      text: currentAnswer?.toString() ?? '',
    );

    return TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Entrez un nombre',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: const Icon(Icons.numbers),
        ),
        onChanged: (value) {
        final numValue = double.tryParse(value);
        if (numValue != null) {
          ref.read(quizSessionProvider.notifier).updateAnswer(
            question.id,
            numValue,
          );
        }
      },
    );
  }

  Widget _buildAssociationWidget(QuestionModel question, dynamic currentAnswer) {
    // TEMPORAIRE : Type association pas encore implémenté
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.construction, size: 48, color: Colors.amber.shade700),
          const SizedBox(height: 16),
          Text(
            'Type de question "Association" en cours de développement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(int totalQuestions) {
    final sessionState = ref.watch(quizSessionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentQuestionIndex == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _currentQuestionIndex < totalQuestions - 1
                  ? _nextQuestion
                  : (sessionState.isSubmitting ? null : _submitQuiz),
              icon: Icon(
                _currentQuestionIndex < totalQuestions - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
              ),
              label: Text(
                _currentQuestionIndex < totalQuestions - 1
                    ? 'Suivant'
                    : 'Soumettre',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentQuestionIndex < totalQuestions - 1
                    ? Theme.of(context).primaryColor
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}