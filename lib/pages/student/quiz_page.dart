import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Ajout de l'import pour Iconsax
import '../../widgets/custom_navbar.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 2;

  final List<Map<String, dynamic>> _quizCategories = [
    {
      'nom': 'Quiz par Matière',
      'icon': Icons.subject,
      'color': Colors.blue,
      'description': 'Quiz par chapitre, thème ou difficulté.',
      'temps': '10-30 min',
      'niveau': 'Tous niveaux',
      'route': '/quiz_par_matiere_selection', 
    },
    {
      'nom': 'Quiz Challenge',
      'icon': Icons.emoji_events,
      'color': Colors.purple,
      'description': 'Défis ardus et quiz originaux.',
      'temps': '20-45 min',
      'niveau': 'Avancé',
      'route': '/quiz_challenge_list', 
    },
    {
      'nom': 'Révision Express',
      'icon': Icons.flash_on, 
      'color': Colors.orange,
      'description': 'Révision rapide sur un sujet/chapitre.',
      'temps': '5-15 min',
      'niveau': 'Adapté',
      'route': '/quiz_express_placeholder', 
    },
    {
      'nom': 'Bilan par Niveau', 
      'icon': Icons.school, 
      'color': Colors.green,
      'description': 'Maîtrise globale par niveau scolaire.',
      'temps': '30-60 min',
      'niveau': 'Spécifique',
      'route': '/quiz_bilan_niveau_placeholder', 
    },
  ];

  final List<Map<String, dynamic>> _quizRecents = [
    {
      'titre': 'Quiz Mathématiques - Algèbre',
      'matiere': 'Mathématiques',
      'points': 15,
      'score': 85,
      'temps': '12 min',
      'date': 'Aujourd\'hui',
    },
    {
      'titre': 'Quiz Physique - Mécanique',
      'matiere': 'Physique',
      'points': 20,
      'score': 72,
      'temps': '18 min',
      'date': 'Hier',
    },
    {
      'titre': 'Quiz Français - Grammaire',
      'matiere': 'Français',
      'points': 10,
      'score': 90,
      'temps': '8 min',
      'date': 'Il y a 2 jours',
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/cours');
        break;
      case 1:
        context.go('/epreuves');
        break;
      case 3:
        context.go('/statistiques');
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
          icon: Icon(Iconsax.notification, color: Colors.grey[700]), // Changé pour Iconsax
          onPressed: () {
            context.go('/notifications'); 
          },
          tooltip: 'Notifications',
        ),
        title: const Text(
          'Quiz',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.setting_2, color: Colors.grey[700]), // Changé pour Iconsax
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purple.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Testez vos connaissances !',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Quiz interactifs pour réviser efficacement',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
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
                            Iconsax.message_question, // Changé pour Iconsax pour cohérence avec FAB
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Types de Quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1, 
                    ),
                    itemCount: _quizCategories.length,
                    itemBuilder: (context, index) {
                      final categorie = _quizCategories[index];
                      return _buildQuizCategoryCard(categorie);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quiz récents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuizRecents(),
                ],
              ),
            ),
          ),
          CustomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
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

  Widget _buildQuizCategoryCard(Map<String, dynamic> categorie) {
    final Color cardColor = categorie['color'] as Color;
    final IconData iconData = categorie['icon'] as IconData; // Les icônes des catégories peuvent rester Material
    final String nom = categorie['nom'] as String;
    final String description = categorie['description'] as String;
    final String route = categorie['route'] as String? ?? '';

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (route.isNotEmpty) {
                context.go(route);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Route non définie pour $nom'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: cardColor,
                      size: 28, 
                    ),
                  ),
                  const SizedBox(height: 8), 
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 11, 
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2), 
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildQuizRecents() {
    return Column(
      children: _quizRecents.map((quiz) {
        final int score = quiz['score'] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple, 
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz['titre'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          quiz['matiere'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${quiz['points']} pts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getScoreColor(score),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz['date'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
