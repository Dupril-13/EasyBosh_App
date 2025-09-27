import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; 
import '../../widgets/custom_navbar.dart';
import '../../models/matiere_model.dart'; 
import '../../models/chapitre_model.dart'; // Importation de ChapitreModel
import '../student/cours/matiere_detail_page.dart';

// Helper function to convert Color to Hex String
String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'; // Format #RRGGBB
}

// Placeholder pour convertir IconData en String (à améliorer si nécessaire)
String _iconDataToString(IconData iconData) {
  // Ceci est une solution très basique. Une meilleure solution dépend de comment vous stockez/récupérez les icônes.
  // Pour l'instant, on utilise le codePoint, mais ce n'est pas idéal pour une utilisation générale.
  // Si vous avez un ensemble limité d'icônes, un map serait mieux.
  if (iconData == Icons.functions) return 'functions';
  if (iconData == Icons.science) return 'science';
  if (iconData == Icons.science_outlined) return 'science_outlined';
  if (iconData == Icons.menu_book) return 'menu_book';
  if (iconData == Icons.language) return 'language';
  if (iconData == Icons.public) return 'public';
  if (iconData == Icons.map) return 'map';
  if (iconData == Icons.psychology) return 'psychology';
  if (iconData == Icons.eco) return 'eco';
  if (iconData == Icons.computer) return 'computer';
  if (iconData == Icons.gavel) return 'gavel';
  if (iconData == Icons.sports_soccer) return 'sports_soccer';
  return iconData.codePoint.toString(); // Fallback
}

class CoursPage extends StatefulWidget {
  const CoursPage({super.key});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> {
  int _currentIndex = 0;
  int _currentMatierePage = 0;
  final PageController _pageController = PageController();

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
    // ... (autres matières omises pour la concision)
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
    const double fabBottomMargin = kBottomNavigationBarHeight + 24.0; 
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.notification, color: Colors.grey[700]),
          onPressed: () => context.go('/notifications'),
          tooltip: 'Notifications',
        ),
        title: const Text('Cours', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.setting_2, color: Colors.grey[700]),
            onPressed: () => context.go('/settings'),
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
                  // ... (Welcome Banner omis pour la concision)
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
                  const Text('Matières disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      SizedBox(
                        height: 316.0, 
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
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), 
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
                      const SizedBox(height: 20.0), 
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
                  const Text('Cours récents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildCoursRecents(),
                  const SizedBox(height: 16),
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
          onPressed: () => context.go('/chatbot'),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9), 
          child: const Icon(Iconsax.message_question, color: Colors.white),
          tooltip: 'EasyBot',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiereMap) {
    // final int currentMatiereId = matiereMap['id'] ?? matiereMap['nom'].toString().hashCode;
    // List<String> chapitreNoms = List<String>.from(matiereMap['chapitres'] ?? []);
    // List<ChapitreModel> chapitresList = [];
    // Commenté pour l'instant car la création de ChapitreModel ici n'est pas compatible
    // avec la définition actuelle de ChapitreModel et les données disponibles dans matiereMap.
    // for (int i = 0; i < chapitreNoms.length; i++) {
    //   chapitresList.add(ChapitreModel(
    //     id: i, 
    //     matiereId: currentMatiereId,
    //     nom: chapitreNoms[i],
    //     description: '', 
          // Les champs suivants n'existent pas dans notre ChapitreModel actuel ou ont des types différents:
          // icon: Icons.subject, 
          // color: Colors.grey,
          // difficulte: 'Moyen',
          // dureeEstimeeMinutes: 0,
          // progression: 0.0,
          // lecons: [],
    //     ordre: i,
    //     createdAt: DateTime.now(),
    //     // createdBy, niveauCode, serieCode, etc. sont manquants ou nécessitent une logique différente
    //   ));
    // }

    // Générer un code placeholder si non fourni, car il est requis par MatiereModel
    final String matiereNom = matiereMap['nom']?.toString() ?? 'N/A';
    final String matiereCode = matiereNom.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final Color? mapColor = matiereMap['color'] as Color?;
    final IconData? mapIconData = matiereMap['icon'] as IconData?;

    MatiereModel matiereAsModel = MatiereModel(
      // L'ID devrait venir de la base de données. Pour la data locale, on peut utiliser un hashCode ou un index.
      // Idéalement, _matieres contiendrait des ID uniques.
      id: matiereMap['id'] as int? ?? matiereNom.hashCode, 
      nom: matiereNom,
      code: matiereMap['code'] as String? ?? matiereCode, // Utiliser code du map si dispo, sinon générer
      description: matiereMap['description'] as String?, // Laisser null si non fourni
      couleur: mapColor != null ? _colorToHex(mapColor) : null, // Convertir Color en String Hex
      icone: mapIconData != null ? _iconDataToString(mapIconData) : null, // Convertir IconData en String
      type: matiereMap['type'] as String? ?? 'obligatoire', // Ajouter un type par défaut
      // Les champs suivants ne sont pas dans notre MatiereModel actuel et sont retirés :
      // niveaux: List<String>.from(matiereMap['niveaux'] ?? []),
      // series: List<String>.from(matiereMap['series'] ?? []),
      // chapitres: chapitresList, 
      // createdAt: DateTime.now(), 
      // updatedAt: DateTime.now(), 
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150, maxHeight: 150),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(matiereMap['chapitres'] as List<dynamic>? ?? []).length} chapitres',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
    // ... (Logique de _buildCoursRecents inchangée pour l'instant)
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
