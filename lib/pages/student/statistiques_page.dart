import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/custom_navbar.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  int _currentIndex = 3;
  int _matiereSelectionnee = 0;

  final List<Map<String, dynamic>> _statsMatiere = [
    {
      'matiere': 'Mathématiques',
      'coursSuivis': 12,
      'coursTotal': 16,
      'quizResolus': 8,
      'quizTotal': 10,
      'epreuvesTraitees': 3,
      'epreuvesTotal': 5,
      'tauxReussite': 78
    },
    {
      'matiere': 'Physique',
      'coursSuivis': 8,
      'coursTotal': 12,
      'quizResolus': 5,
      'quizTotal': 8,
      'epreuvesTraitees': 2,
      'epreuvesTotal': 4,
      'tauxReussite': 65
    },
    {
      'matiere': 'Chimie',
      'coursSuivis': 6,
      'coursTotal': 12,
      'quizResolus': 3,
      'quizTotal': 8,
      'epreuvesTraitees': 1,
      'epreuvesTotal': 4,
      'tauxReussite': 55
    },
    {
      'matiere': 'Français',
      'coursSuivis': 15,
      'coursTotal': 18,
      'quizResolus': 10,
      'quizTotal': 12,
      'epreuvesTraitees': 4,
      'epreuvesTotal': 5,
      'tauxReussite': 82
    },
    {
      'matiere': 'Anglais',
      'coursSuivis': 10,
      'coursTotal': 14,
      'quizResolus': 7,
      'quizTotal': 9,
      'epreuvesTraitees': 2,
      'epreuvesTotal': 4,
      'tauxReussite': 76
    },
    {
      'matiere': 'Histoire-Géo',
      'coursSuivis': 7,
      'coursTotal': 13,
      'quizResolus': 4,
      'quizTotal': 8,
      'epreuvesTraitees': 2,
      'epreuvesTotal': 5,
      'tauxReussite': 60
    },
  ];

  double _safeDivide(num? a, num? b) {
    if (a == null || b == null || b == 0) return 0.0;
    final res = a / b;
    return res.clamp(0.0, 1.0);
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        context.go('/cours');
        break;
      case 1:
        context.go('/epreuves');
        break;
      case 2:
        context.go('/quiz');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fabBottomMargin = kBottomNavigationBarHeight + 24.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.notification, color: Colors.grey[700]),
          onPressed: () {
            context.go('/notifications');
          },
          tooltip: 'Notifications',
        ),
        title: const Text(
          'Statistiques',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.setting_2, color: Colors.grey[700]),
            onPressed: () {
              context.go('/settings');
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    'Aperçu global',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildGlobalStats(),
                  const SizedBox(height: 24),
                  const Text(
                    'Progression par matière',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildMatiereSelector(),
                  const SizedBox(height: 16),
                  _buildSelectedMatiereStats(),
                ],
              ),
            ),
          ),
          CustomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: fabBottomMargin),
        child: FloatingActionButton(
          onPressed: () {
            context.go('/chatbot');
          },
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
          child: const Icon(Iconsax.message_question, color: Colors.white), // Changé pour Iconsax
          tooltip: 'EasyBot',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre progression !',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Suivez vos performances et améliorez-vous',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.chart_1, // Changé pour Iconsax pour cohérence
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Cours suivis', '68', Iconsax.book_1, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Quiz complétés', '42', Iconsax.message_question, Colors.purple)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Épreuves traitées', '24', Iconsax.document_text_1, Colors.orange)),
      ],
    );
  }

  Widget _buildMatiereSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statsMatiere.length,
        itemBuilder: (context, index) {
          final matiere = _statsMatiere[index]['matiere'];
          final isSelected = index == _matiereSelectionnee;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(matiere),
              selected: isSelected,
              onSelected: (_) => setState(() => _matiereSelectionnee = index),
              selectedColor: Colors.green,
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedMatiereStats() {
    final matiere = _statsMatiere[_matiereSelectionnee];

    final coursFraction = _safeDivide(matiere['coursSuivis'], matiere['coursTotal']);
    final epreuvesFraction = _safeDivide(matiere['epreuvesTraitees'], matiere['epreuvesTotal']);
    final quizFraction = _safeDivide(matiere['quizResolus'], matiere['quizTotal']);
    final tauxReussiteFraction = _safeDivide(matiere['tauxReussite'], 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(matiere['matiere'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _buildProgressBarWithPercent(
            "Cours suivis (${matiere['coursSuivis']}/${matiere['coursTotal']})",
            coursFraction,
            Colors.purple,
          ),
          const SizedBox(height: 12),

          _buildProgressBarWithPercent(
            "Épreuves traitées (${matiere['epreuvesTraitees']}/${matiere['epreuvesTotal']})",
            epreuvesFraction,
            Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildProgressBarWithPercent(
            "Quiz résolus (${matiere['quizResolus']}/${matiere['quizTotal']})",
            quizFraction,
            Colors.green,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          const Text('Résultats des quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          _buildProgressBarWithPercent('Taux de réussite', tauxReussiteFraction, Colors.green),
          const SizedBox(height: 10),
          _buildProgressBarWithPercent('Taux d\'échec', (1 - tauxReussiteFraction).clamp(0.0, 1.0), Colors.red),
        ],
      ),
    );
  }

  Widget _buildProgressBarWithPercent(String label, double value, Color color) {
    final clampedValue = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: LinearProgressIndicator(
              value: clampedValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text("${(clampedValue * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
