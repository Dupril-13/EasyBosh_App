import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_navbar.dart';
import 'test_navigation_page.dart'; // Import for TestNavigationPage
import '../../models/matiere_model.dart'; // Import for MatiereModel
import 'matiere_detail_page.dart'; // Import for MatiereDetailPage

class CoursPage extends StatefulWidget {
  const CoursPage({super.key});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> {
  int _currentIndex = 0;
  int _currentMatierePage = 0;
  final PageController _pageController = PageController();

  // Matières exactement comme votre V1
  final List<Map<String, dynamic>> _matieres = [
    {
      'nom': 'Maths',
      'icon': Icons.functions,
      'color': Colors.blue,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Algèbre', 'Géométrie', 'Trigonométrie', 'Statistiques']
    },
    {
      'nom': 'Physique',
      'icon': Icons.science,
      'color': Colors.orange,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Mécanique', 'Électricité', 'Optique', 'Thermodynamique']
    },
    {
      'nom': 'Chimie',
      'icon': Icons.science_outlined,
      'color': Colors.green,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Atomes', 'Réactions', 'Solutions', 'Organique']
    },
    {
      'nom': 'Français',
      'icon': Icons.menu_book,
      'color': Colors.purple,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Grammaire', 'Conjugaison', 'Littérature', 'Expression']
    },
    {
      'nom': 'Anglais',
      'icon': Icons.language,
      'color': Colors.red,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Grammar', 'Vocabulary', 'Comprehension', 'Expression']
    },
    {
      'nom': 'Histoire',
      'icon': Icons.public,
      'color': Colors.brown,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Antiquité', 'Moyen Âge', 'Temps Modernes', 'Époque Contemporaine']
    },
    {
      'nom': 'Géographie',
      'icon': Icons.map,
      'color': Colors.greenAccent.shade700,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Cartographie', 'Climatologie', 'Géopolitique', 'Urbanisme']
    },
    {
      'nom': 'Philosophie',
      'icon': Icons.psychology,
      'color': Colors.teal,
      'niveaux': ['1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['La Conscience', 'L\'Inconscient', 'La Liberté', 'L\'État']
    },
    {
      'nom': 'SVT',
      'icon': Icons.eco,
      'color': Colors.lightGreen,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['C', 'D'],
      'chapitres': ['Biologie Cellulaire', 'Géologie', 'Écologie', 'Génétique']
    },
    {
      'nom': 'Informatique',
      'icon': Icons.computer,
      'color': Colors.indigo,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['C', 'D', 'TI'],
      'chapitres': ['Algorithmique', 'Programmation', 'Réseaux', 'Bases de Données']
    },
    {
      'nom': 'ECM',
      'icon': Icons.gavel,
      'color': Colors.amber,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Droits de l\'Homme', 'Institutions', 'Citoyenneté', 'Morale']
    },
    {
      'nom': 'EPS',
      'icon': Icons.sports_soccer,
      'color': Colors.deepOrange,
      'niveaux': ['3ème', '1ère', 'Tle'],
      'series': ['A', 'C', 'D', 'TI'],
      'chapitres': ['Athlétisme', 'Sports Collectifs', 'Gymnastique', 'Natation']
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 1:
        context.go('/epreuves');
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cours',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.blue.shade700],
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
                                'Bienvenue dans vos cours !',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Explorez les matières et progressez à votre rythme',
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
                            Icons.school,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Matières disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentMatierePage = index;
                            });
                          },
                          itemCount: (_matieres.length / 4).ceil(),
                          itemBuilder: (context, pageIndex) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: pageIndex == (_matieres.length / 4).ceil() - 1 ? 0 : 16.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.05,
                                ),
                                itemCount: 4,
                                itemBuilder: (context, gridIndex) {
                                  final itemIndex = pageIndex * 4 + gridIndex;
                                  if (itemIndex < _matieres.length) {
                                    final matiereMap = _matieres[itemIndex];
                                    return _buildMatiereCard(matiereMap);
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate((_matieres.length / 4).ceil(), (index) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentMatierePage == index ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cours récents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCoursRecents(),
                  const SizedBox(height: 16),
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

  Widget _buildMatiereCard(Map<String, dynamic> matiereMap) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 150,
        maxHeight: 150,
      ),
      child: Container(
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
              final int currentMatiereId = matiereMap['id'] ?? matiereMap['nom'].toString().hashCode;
              List<String> chapitreNoms = List<String>.from(matiereMap['chapitres'] ?? []);
              List<ChapitreModel> chapitresList = [];
              for (int i = 0; i < chapitreNoms.length; i++) {
                chapitresList.add(ChapitreModel(
                  id: i, // Placeholder ID for chapitre
                  matiereId: currentMatiereId,
                  nom: chapitreNoms[i],
                  description: '', 
                  icon: Icons.subject, 
                  color: Colors.grey,
                  difficulte: 'Moyen',
                  dureeEstimeeMinutes: 0,
                  progression: 0.0,
                  lecons: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
              }

              MatiereModel matiereAsModel = MatiereModel(
                id: currentMatiereId,
                nom: matiereMap['nom']?.toString() ?? 'N/A',
                description: matiereMap['description']?.toString() ?? '',
                icon: matiereMap['icon'] as IconData? ?? Icons.book,
                color: matiereMap['color'] as Color? ?? Colors.blue,
                niveaux: List<String>.from(matiereMap['niveaux'] ?? []),
                series: List<String>.from(matiereMap['series'] ?? []),
                chapitres: chapitresList,
                createdAt: DateTime.now(), // Default value
                updatedAt: DateTime.now(), // Default value
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatiereDetailPage(matiere: matiereAsModel),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (matiereMap['color'] as Color? ?? Colors.blue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      matiereMap['icon'] as IconData? ?? Icons.book,
                      color: matiereMap['color'] as Color? ?? Colors.blue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matiereMap['nom']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(matiereMap['chapitres'] as List<dynamic>? ?? []).length} chapitres',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursRecents() {
    final coursRecents = [
      {'titre': 'Algèbre - Équations du 2nd degré', 'matiere': 'Mathématiques', 'duree': '45 min'},
      {'titre': 'Mécanique - Les forces', 'matiere': 'Physique', 'duree': '30 min'},
      {'titre': 'Grammaire - Les temps composés', 'matiere': 'Français', 'duree': '40 min'},
    ];

    return Column(
      children: coursRecents.map((cours) {
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
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cours['titre']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cours['matiere']!,
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
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cours['duree']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
