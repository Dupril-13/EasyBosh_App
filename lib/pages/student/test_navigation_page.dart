// lib/pages/student/test_navigation_page.dart
import 'package:flutter/material.dart';
import '../../models/matiere_model.dart';
import '../../services/mock_data_service.dart';
import 'matiere_detail_page.dart';

class TestNavigationPage extends StatelessWidget {
  const TestNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final matieres = MockDataService.getMatieres();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Test Navigation Jalon 4'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Test Navigation Matières → Chapitres → Leçons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cliquez sur une matière pour tester :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Boutons de test pour chaque matière
            ...matieres.map((matiere) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatiereDetailPage(matiere: matiere),
                    ),
                  );
                },
                icon: Icon(matiere.icon),
                label: Text(
                  '${matiere.nom} (${matiere.nombreChapitres} chapitres)',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: matiere.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )).toList(),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Ce que vous pouvez tester :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text('• Navigation Matière → Chapitres'),
                  Text('• Clic sur chapitre → Leçons'),
                  Text('• Clic sur leçon → Contenu détaillé'),
                  Text('• Navigation précédent/suivant entre leçons'),
                  Text('• Bouton terminer/revoir les leçons'),
                  Text('• Barres de progression'),
                  Text('• Types de contenu (texte, vidéo, quiz)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}