import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_navbar.dart';

class EpreuvesPage extends StatefulWidget {
  const EpreuvesPage({super.key});

  @override
  State<EpreuvesPage> createState() => _EpreuvesPageState();
}

class _EpreuvesPageState extends State<EpreuvesPage> {
  int _currentIndex = 1;

  final List<Map<String, dynamic>> _categories = [
    {'nom': 'Anciens Sujets d\'Examen', 'icon': Icons.history_edu_outlined, 'route': '/anciens_sujets', 'color': Colors.blue, 'nombreSujets': 120},
    {'nom': 'Sujets de Collèges', 'icon': Icons.school_outlined, 'route': '/colleges_connus', 'color': Colors.orange, 'nombreSujets': 75},
    {'nom': 'Examens Blancs', 'icon': Icons.lightbulb_outline, 'route': '/examens_blancs', 'color': Colors.green, 'nombreSujets': 50},
    {'nom': 'Épreuves Exclusives', 'icon': Icons.star_border_outlined, 'route': '/epreuves_exclusives', 'color': Colors.purple, 'nombreSujets': 30},
  ];

  void _navigateToCategory(String route) {
    // Implémentation de navigation vers la catégorie d'épreuves
    switch (route) {
      case '/anciens_sujets':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation vers Anciens Sujets d\'Examen')),
        );
        break;
      case '/colleges_connus':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation vers Sujets de Collèges')),
        );
        break;
      case '/examens_blancs':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation vers Examens Blancs')),
        );
        break;
      case '/epreuves_exclusives':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation vers Épreuves Exclusives')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie non implémentée')),
        );
    }
  }

  final List<Map<String, dynamic>> _epreuves = [
    {
      'titre': 'BEPC 2024 - Mathématiques',
      'matiere': 'Mathématiques',
      'duree': '2h 30',
      'questions': 25,
      'niveau': '3ème',
      'date': '2024-06-15',
      'status': 'disponible',
    },
    {
      'titre': 'Bac A 2024 - Philosophie',
      'matiere': 'Philosophie',
      'duree': '4h',
      'questions': 3,
      'niveau': 'Tle',
      'date': '2024-06-20',
      'status': 'disponible',
    },
    {
      'titre': 'Bac C 2024 - Mathématiques',
      'matiere': 'Mathématiques',
      'duree': '4h',
      'questions': 4,
      'niveau': 'Tle',
      'date': '2024-06-18',
      'status': 'disponible',
    },
    {
      'titre': 'Bac D 2024 - Biologie',
      'matiere': 'Biologie',
      'duree': '3h',
      'questions': 3,
      'niveau': 'Tle',
      'date': '2024-06-22',
      'status': 'disponible',
    },
    {
      'titre': 'Probatoire A 2024 - Français',
      'matiere': 'Français',
      'duree': '3h',
      'questions': 2,
      'niveau': '1ère',
      'date': '2024-06-25',
      'status': 'disponible',
    },
    {
      'titre': 'BEPC 2023 - Histoire-Géo',
      'matiere': 'Histoire-Géographie',
      'duree': '2h',
      'questions': 20,
      'niveau': '3ème',
      'date': '2023-06-10',
      'status': 'terminee',
    },
    {
      'titre': 'Probatoire C 2024 - Physique',
      'matiere': 'Physique',
      'duree': '3h',
      'questions': 4,
      'niveau': '1ère',
      'date': '2024-06-28',
      'status': 'disponible',
    },
    {
      'titre': 'BEPC 2024 - Anglais',
      'matiere': 'Anglais',
      'duree': '2h',
      'questions': 30,
      'niveau': '3ème',
      'date': '2024-06-12',
      'status': 'disponible',
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Navigation vers les autres pages
    switch (index) {
      case 0:
        context.go('/cours');
        break;
      case 2:
        context.go('/quiz');
        break;
      case 3:
        context.go('/statistiques');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Épreuves',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onPressed: () {
              context.go('/settings');
            },
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
                  // En-tête avec image
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.orange.shade700],
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
                                'Préparez vos examens !',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Entraînez-vous avec les épreuves officielles',
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
                            Icons.assignment,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildCategoriesGrid(),

                  const SizedBox(height: 24),

                  const Text(
                    'Récemment Consultées',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEpreuvesList(),

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
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category, category['color'] as Color);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Color iconColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCategory(category['route']),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(category['icon'] as IconData, size: 36, color: iconColor),
              const SizedBox(height: 8),
              Text(
                category['nom'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${category['nombreSujets'] ?? 0} sujets',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpreuvesList() {
    final epreuvesDisponibles = _epreuves.take(3).toList();
    return Column(
      children: epreuvesDisponibles.map((epreuve) {
        final isTerminee = epreuve['status'] == 'terminee';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ouverture de ${epreuve['titre']}')));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                epreuve['titre'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                epreuve['matiere'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isTerminee
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isTerminee ? 'Terminée' : 'Disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTerminee ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.schedule,
                          epreuve['duree'] as String,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.quiz,
                          '${epreuve['questions'] as int} questions',
                          Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.grade,
                          epreuve['niveau'] as String,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${epreuve['date'] as String}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Action spécifique
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTerminee ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            isTerminee ? 'Résultats' : 'Commencer',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}