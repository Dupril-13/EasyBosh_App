
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/quiz_session_provider.dart';
import '../../../models/question_model.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final int quizId;

  const QuizPlayPage({super.key, required this.quizId});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    // Démarrer une nouvelle session de quiz lorsque la page est chargée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizSessionProvider.notifier).startQuiz(widget.quizId);
    });
  }

  void _nextQuestion(int totalQuestions) {
    setState(() {
      if (_currentQuestionIndex < totalQuestions - 1) {
        _currentQuestionIndex++;
      }
    });
  }

  void _previousQuestion() {
    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      }
    });
  }

  void _submitQuiz(List<QuestionModel> questions) {
    final resultsData = ref.read(quizSessionProvider.notifier).submitQuiz(questions);
    context.go('/quiz/results/1', extra: resultsData);
  }

  Widget _buildOptions(QuestionModel question) {
    final isMultipleChoice = question.type == 'qcm_multiple';
    final sessionState = ref.watch(quizSessionProvider);

    return Column(
      children: question.options.map((option) {
        if (isMultipleChoice) {
          final isSelected = sessionState.answers[question.id]?.contains(option.id) ?? false;
          return CheckboxListTile(
            title: Text(option.texte),
            value: isSelected,
            onChanged: (bool? value) {
              ref.read(quizSessionProvider.notifier).selectAnswer(question.id, option.id, true);
            },
          );
        } else {
          return RadioListTile<int>(
            title: Text(option.texte),
            value: option.id,
            groupValue: sessionState.answers[question.id]?.firstOrNull,
            onChanged: (value) {
              if (value != null) {
                ref.read(quizSessionProvider.notifier).selectAnswer(question.id, value, false);
              }
            },
          );
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizDetailAsync = ref.watch(quizDetailProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz en cours', style: TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
      ),
      body: quizDetailAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('Ce quiz ne contient aucune question.'));
          }
          final totalQuestions = questions.length;
          final currentQuestion = questions[_currentQuestionIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}/$totalQuestions',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / totalQuestions,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              currentQuestion.texte,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20),
                            _buildOptions(currentQuestion),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                      onPressed: _currentQuestionIndex == 0 ? null : _previousQuestion,
                      style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor, backgroundColor: Colors.white, side: BorderSide(color: Theme.of(context).primaryColor)),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Suivant'),
                      onPressed: _currentQuestionIndex == totalQuestions - 1 ? null : () => _nextQuestion(totalQuestions),
                      style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor, backgroundColor: Colors.white, side: BorderSide(color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_currentQuestionIndex == totalQuestions - 1)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Soumettre le Quiz'),
                    onPressed: () => _submitQuiz(questions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
