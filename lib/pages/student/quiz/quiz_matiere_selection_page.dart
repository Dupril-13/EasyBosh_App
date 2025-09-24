import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importer go_router

class QuizMatiereSelectionPage extends StatelessWidget {
  const QuizMatiereSelectionPage({super.key});

  // Données factices pour les matières
  final List<Map<String, dynamic>> _matieres = const [
    {'nom': 'Mathématiques', 'icon': Icons.calculate, 'color': Colors.blue},
    {'nom': 'Physique-Chimie', 'icon': Icons.science, 'color': Colors.orange},
    {'nom': 'SVT', 'icon': Icons.eco, 'color': Colors.green},
    {'nom': 'Français', 'icon': Icons.translate, 'color': Colors.purple},
    {'nom': 'Anglais', 'icon': Icons.language, 'color': Colors.red},
    {'nom': 'Histoire-Géographie', 'icon': Icons.public, 'color': Colors.teal},
    {'nom': 'Philosophie', 'icon': Icons.psychology, 'color': Colors.brown},
    {'nom': 'Informatique', 'icon': Icons.computer, 'color': Colors.indigo},
  ];

  @override
  Widget build(BuildContext context) {
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
              context.go('/quiz'); // Fallback vers la page principale des quiz
            }
          },
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _matieres.length,
        itemBuilder: (context, index) {
          final matiere = _matieres[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding vertical ajouté
              leading: Icon(matiere['icon'] as IconData, color: matiere['color'] as Color, size: 30),
              title: Text(matiere['nom'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                context.go('/quiz_list_par_matiere', extra: matiere['nom'] as String);
              },
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
      ),
    );
  }
}
