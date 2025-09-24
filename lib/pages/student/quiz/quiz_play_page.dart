import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './quiz_results_page.dart'; 

class QuizPlayPage extends StatefulWidget {
  final Map<String, dynamic> quizDetails;

  const QuizPlayPage({super.key, required this.quizDetails});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    final dummyResultsForTotal = QuizResultsPage.getDummyResults();
    _totalQuestions = (dummyResultsForTotal['questions'] as List).length;
    if (_totalQuestions == 0) _totalQuestions = 5; 
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _totalQuestions - 1) {
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

  void _submitQuiz() {
    final Map<String, dynamic> resultsData = QuizResultsPage.getDummyResults();
    resultsData['quizTitle'] = widget.quizDetails['titre'] as String? ?? resultsData['quizTitle'];
    context.go('/quiz_results', extra: resultsData);
  }

  @override
  Widget build(BuildContext context) {
    final String quizTitle = widget.quizDetails['titre'] as String? ?? 'Quiz en cours';

    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle, style: const TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Quitter le quiz ?'),
                content: const Text('Votre progression ne sera pas sauvegardée si vous quittez maintenant.'),
                actions: [
                  TextButton(
                    child: const Text('Rester'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  TextButton(
                    child: const Text('Quitter', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Ferme le dialogue
                      // Navigation explicite pour quitter
                      final String? matiereNom = widget.quizDetails['matiere_nom'] as String?;
                      if (matiereNom != null && matiereNom.isNotEmpty) {
                        context.go('/quiz_list_par_matiere', extra: matiereNom);
                      } else {
                        context.go('/quiz'); // Fallback à la page principale des quiz
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Question ${_currentQuestionIndex + 1}/$_totalQuestions',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
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
                  child: Center(
                    child: Text(
                      'Contenu de la question ${_currentQuestionIndex + 1} ici\n(Choix multiples, vrai/faux, etc.)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                  onPressed: _currentQuestionIndex == _totalQuestions - 1 ? null : _nextQuestion, 
                  style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor, backgroundColor: Colors.white, side: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentQuestionIndex == _totalQuestions - 1) 
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Soumettre le Quiz'),
                onPressed: _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
