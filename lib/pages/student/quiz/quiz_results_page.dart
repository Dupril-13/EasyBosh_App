// ================================================
// lib/pages/student/quiz/quiz_results_page.dart
// Page des résultats connectée à la BD
// ================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/quiz_model.dart';
import '../../../models/quiz_session_model.dart';
import '../../../models/question_model.dart';

class QuizResultsPage extends StatelessWidget {
  final Map<String, dynamic> results;

  const QuizResultsPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final QuizSessionModel session = results['session'] as QuizSessionModel;
    final QuizModel quiz = results['quiz'] as QuizModel;
    final List<QuestionModel> questions =
    results['questions'] as List<QuestionModel>;
    final Map<String, dynamic> userAnswers =
    results['userAnswers'] as Map<String, dynamic>;

    final double percentageScore =
        (session.noteSurBaremeQuiz ?? 0) / 20 * 100;
    final int correctCount = _calculateCorrectAnswers(questions, userAnswers);
    final int incorrectCount = questions.length - correctCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, quiz.nom),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Carte de résumé
            _buildSummaryCard(
              context,
              session,
              correctCount,
              questions.length,
              percentageScore,
              incorrectCount,
            ),

            const SizedBox(height: 32),

            // Détail des réponses (si correction autorisée)
            if (quiz.afficherCorrectionFinale) ...[
              _buildSectionHeader(context, 'Détail des réponses'),
              const SizedBox(height: 20),
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildQuestionResultCard(
                    context,
                    question,
                    index + 1,
                    userAnswers,
                  ),
                );
              }).toList(),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La correction détaillée n\'est pas disponible pour ce quiz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Boutons d'action
            _buildActionButtons(context, quiz),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  int _calculateCorrectAnswers(
      List<QuestionModel> questions,
      Map<String, dynamic> userAnswers,
      ) {
    int correctCount = 0;

    for (final question in questions) {
      final userAnswer = userAnswers[question.id.toString()];
      if (userAnswer == null) continue;

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

      if (isCorrect) correctCount++;
    }

    return correctCount;
  }

  AppBar _buildAppBar(BuildContext context, String quizTitle) {
    return AppBar(
      title: Text(
        quizTitle,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1.0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.grey[700], size: 24),
        onPressed: () {
          // Retour à la page quiz hub
          context.go('/quiz');
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      QuizSessionModel session,
      int correctCount,
      int totalQuestions,
      double percentageScore,
      int incorrectCount,
      ) {
    final Color scoreColor = _getScoreColor(percentageScore);
    final String minutes = (session.tempsPasse ~/ 60).toString();
    final String seconds = (session.tempsPasse % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône de résultat
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.1),
            ),
            child: Icon(
              session.reussi == true
                  ? Icons.emoji_events
                  : Icons.info_outline,
              size: 40,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            session.reussi == true ? 'Félicitations !' : 'Quiz terminé',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 8),

          // Score sur 20
          Text(
            '${session.noteSurBaremeQuiz?.toStringAsFixed(1) ?? '0'} / 20',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 4),

          // Pourcentage
          Text(
            '${percentageScore.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                'Correctes',
                correctCount.toString(),
                const Color(0xFF10B981),
                Icons.check_circle,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                context,
                'Incorrectes',
                incorrectCount.toString(),
                const Color(0xFFEF4444),
                Icons.cancel,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                context,
                'Temps',
                '$minutes:$seconds',
                const Color(0xFF6366F1),
                Icons.schedule,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.grey[200],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981); // Vert
    if (percentage >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      Color color,
      IconData icon,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionResultCard(
      BuildContext context,
      QuestionModel question,
      int questionNumber,
      Map<String, dynamic> userAnswers,
      ) {
    final userAnswer = userAnswers[question.id.toString()];
    final correctOptionIds = question.options
        .where((opt) => opt.estCorrecte)
        .map((opt) => opt.id)
        .toSet();

    bool isCorrect = false;
    Set<int> userSelectedIds = {};

    if (question.type == QuestionType.qcmUnique ||
        question.type == QuestionType.vraiFaux) {
      isCorrect = correctOptionIds.contains(userAnswer);
      if (userAnswer != null) {
        userSelectedIds = {userAnswer as int};
      }
    } else if (question.type == QuestionType.qcmMultiple && userAnswer is List) {
      userSelectedIds = Set<int>.from(userAnswer.map((e) => e as int));
      isCorrect = userSelectedIds.length == correctOptionIds.length &&
          userSelectedIds.containsAll(correctOptionIds);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question $questionNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.texte,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${question.points} pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Options avec indication
            ...question.options.map((option) {
              final isUserSelected = userSelectedIds.contains(option.id);
              final isCorrectOption = option.estCorrecte;

              Color? backgroundColor;
              Color? borderColor;
              IconData? icon;

              if (isCorrectOption) {
                backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
                borderColor = const Color(0xFF10B981);
                icon = Icons.check;
              } else if (isUserSelected && !isCorrectOption) {
                backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
                borderColor = const Color(0xFFEF4444);
                icon = Icons.close;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.shade300,
                    width: borderColor != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.texte,
                        style: TextStyle(
                          fontSize: 14,
                          color: borderColor ?? Colors.grey.shade700,
                          fontWeight: borderColor != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Explication
            if (question.explication != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.explication!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, QuizModel quiz) {
    return Column(
      children: [
        // Bouton Recommencer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Retour à la page du quiz pour recommencer
              context.go('/quiz_play', extra: quiz);
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Recommencer le quiz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton Retour aux quiz
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/quiz');
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              'Retour aux quiz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}