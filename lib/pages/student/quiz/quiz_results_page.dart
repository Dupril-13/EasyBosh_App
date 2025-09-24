import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizResultsPage extends StatelessWidget {
  final Map<String, dynamic> results;

  const QuizResultsPage({super.key, required this.results});

  static Map<String, dynamic> getDummyResults() {
    return {
      'quizTitle': 'Quiz d\'Algèbre Avancée',
      'score': 7,
      'totalQuestions': 10,
      'timeTaken': '15:32',
      'questions': [
        {
          'questionText': 'Quelle est la valeur de x si 2x + 5 = 15?',
          'userAnswer': '5',
          'correctAnswer': '5',
          'isCorrect': true,
        },
        {
          'questionText': 'Factorisez x² - 9.',
          'userAnswer': '(x-3)(x+2)',
          'correctAnswer': '(x-3)(x+3)',
          'isCorrect': false,
        },
        {
          'questionText': 'Simplifiez √72.',
          'userAnswer': '6√2',
          'correctAnswer': '6√2',
          'isCorrect': true,
        },
        {
          'questionText': 'Résoudre l\'équation : x² - 5x + 6 = 0',
          'userAnswer': 'x=2 ou x=3',
          'correctAnswer': 'x=2 ou x=3',
          'isCorrect': true,
        },
        {
          'questionText': 'Quelle est la dérivée de f(x) = 3x³ - 2x + 1?',
          'userAnswer': '9x² - 2x',
          'correctAnswer': '9x² - 2',
          'isCorrect': false,
        },
      ],
    };
  }

  AppBar _buildStandardAppBar(BuildContext context, String quizTitle) {
    return AppBar(
      title: Text(
        quizTitle,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Colors.white,
      elevation: 1.0, // Subtile élévation
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/quiz');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String quizTitle = results['quizTitle'] ?? 'Résultats du Quiz';
    final int score = results['score'] ?? 0;
    final int totalQuestions = results['totalQuestions'] ?? (results['questions'] as List?)?.length ?? 0;
    final String timeTaken = results['timeTaken'] ?? 'N/A';
    final List<Map<String, dynamic>> questions =
        List<Map<String, dynamic>>.from(results['questions'] ?? []);

    final double percentageScore = totalQuestions > 0 ? (score / totalQuestions) : 0;
    final int correctAnswers = score;
    final int incorrectAnswers = totalQuestions - score;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildStandardAppBar(context, quizTitle), // Utilisation de l'AppBar standard
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSummaryCard(context, correctAnswers, totalQuestions, percentageScore, timeTaken, incorrectAnswers),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Détail des réponses'),
            const SizedBox(height: 20),
            if (questions.isEmpty)
              _buildEmptyState(context)
            else
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final questionData = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildQuestionResultCard(context, questionData, index + 1),
                );
              }).toList(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun détail de question disponible.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int correctAnswers, int totalQuestions, double percentageScore, String timeTaken, int incorrectAnswers) {
    Color progressColor = _getScoreColor(percentageScore * 100); // percentageScore est de 0.0 à 1.0

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Votre Résultat', // Titre modifié
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 12, // Hauteur de la barre de progression
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentageScore,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(percentageScore * 100).toStringAsFixed(0)}% de bonnes réponses ($correctAnswers/$totalQuestions)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Correctes',
                  correctAnswers.toString(),
                  const Color(0xFF10B981),
                  Icons.check_circle,
                ),
                _buildVerticalDivider(),
                _buildStatItem(
                  context,
                  'Incorrectes',
                  incorrectAnswers.toString(),
                  const Color(0xFFEF4444),
                  Icons.cancel,
                ),
                _buildVerticalDivider(),
                _buildStatItem(
                  context,
                  'Temps',
                  timeTaken,
                  const Color(0xFF6366F1),
                  Icons.schedule,
                ),
              ],
            ),
          ],
        ),
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

  Color _getScoreColor(double percentage) { // Prend un pourcentage de 0 à 100
    if (percentage >= 80) return const Color(0xFF10B981); // Vert
    if (percentage >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color, IconData icon) {
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildQuestionResultCard(BuildContext context, Map<String, dynamic> questionData, int questionNumber) {
    final String questionText = questionData['questionText'] ?? 'Question non disponible';
    final String userAnswer = questionData['userAnswer'] ?? '-';
    final String correctAnswer = questionData['correctAnswer'] ?? '-';
    final bool isCorrect = questionData['isCorrect'] ?? false;

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
          color: isCorrect ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3),
          width: 1.5, // bordure légèrement affinée
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 15.5, // Taille légèrement ajustée
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                      height: 1.45, // Interligne ajusté
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre réponse: $userAnswer',
                          style: TextStyle(
                            color: isCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626), // Couleurs assombries pour contraste
                            fontSize: 14.5, // Taille ajustée
                            fontWeight: FontWeight.w600, // Graisse augmentée
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF059669),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Réponse correcte: $correctAnswer',
                              style: const TextStyle(
                                color: Color(0xFF059669), // Couleur assombrie
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor, width: 1.5), // Largeur de bordure ajustée
            ),
            child: OutlinedButton.icon(
              icon: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColor, size: 22), // Taille icône ajustée
              label: Text('Recommencer', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 15)), // Taille police ajustée
              style: OutlinedButton.styleFrom(
                side: BorderSide.none, // La bordure est déjà sur le Container
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // Doit correspondre au Container ou être légèrement inférieur
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fonctionnalité Recommencer bientôt disponible!'),
                    backgroundColor: Theme.of(context).primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              label: const Text(
                'Accueil Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                context.go('/quiz');
              },
            ),
          ),
        ),
      ],
    );
  }
}
