
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/quiz_provider.dart';
import '../../../models/quiz_model.dart';

class QuizListByMatierePage extends ConsumerWidget {
  final int matiereId;

  const QuizListByMatierePage({super.key, required this.matiereId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizListAsync = ref.watch(quizListProvider(matiereId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Disponibles'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quiz/selection-matiere');
            }
          },
        ),
      ),
      body: quizListAsync.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const Center(
              child: Text('Aucun quiz disponible pour cette matière pour le moment.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(quiz.description ?? 'Pas de description pour ce quiz.', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(Icons.question_answer, '${quiz.nombreQuestions} questions', Colors.blue),
                          if (quiz.tempsLimite != null)
                            _buildInfoChip(Icons.timer_outlined, '${quiz.tempsLimite} min', Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/quiz/play/${quiz.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                          child: const Text('Commencer le Quiz'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
