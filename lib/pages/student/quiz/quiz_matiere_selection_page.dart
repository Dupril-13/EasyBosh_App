
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/quiz_provider.dart';
import '../../../models/matiere_model.dart';

class QuizMatiereSelectionPage extends ConsumerWidget {
  const QuizMatiereSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matieresAsync = ref.watch(matieresWithQuizzesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une Matière'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quiz');
            }
          },
        ),
      ),
      body: matieresAsync.when(
        data: (matieres) {
          if (matieres.isEmpty) {
            return const Center(
              child: Text('Aucune matière avec des quiz disponibles pour le moment.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: matieres.length,
            itemBuilder: (context, index) {
              final matiere = matieres[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  leading: Icon(Icons.calculate, color: Colors.blue, size: 30), // Placeholder icon
                  title: Text(matiere.nom, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Navigate to quiz list for the selected matiere
                    context.go('/quiz/list-par-matiere/${matiere.id}');
                  },
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erreur: $err'),
        ),
      ),
    );
  }
}
