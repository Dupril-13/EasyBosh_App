import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart'; // Import pour currentUserProvider
import 'package:easybosh_v2/models/user_model.dart'; // Import pour UserModel
import '../../widgets/custom_navbar.dart';
import '../../models/matiere_model.dart';
import '../student/cours/matiere_detail_page.dart';

// Helper function to convert Hex String to Color
Color _hexToColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return Colors.grey; // Default color
  }
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor; // Add alpha if missing
  }
  if (hexColor.length == 8) {
    try {
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return Colors.grey; // Fallback in case of parsing error
    }
  }
  return Colors.grey; // Default color if format is still wrong
}

// Helper function to convert icon string to IconData
IconData _stringToIconData(String? iconName) {
  if (iconName == null || iconName.isEmpty) {
    return Icons.help_outline; // Default icon
  }
  switch (iconName) {
    case 'functions': return Icons.functions;
    case 'science': return Icons.science;
    case 'science_outlined': return Icons.science_outlined;
    case 'menu_book': return Icons.menu_book;
    case 'language': return Icons.language;
    case 'public': return Icons.public;
    case 'map': return Icons.map;
    case 'psychology': return Icons.psychology;
    case 'eco': return Icons.eco;
    case 'computer': return Icons.computer;
    case 'gavel': return Icons.gavel;
    case 'sports_soccer': return Icons.sports_soccer;
    case 'biotech_outlined': return Icons.biotech_outlined;
    case 'translate': return Iconsax.translate;
    case 'music_note': return Icons.music_note;
    case 'palette': return Icons.palette;
    case 'theater_comedy': return Icons.theater_comedy;
    case 'home_work': return Icons.home_work;
    default:
      return Icons.help_outline;
  }
}

class CoursPage extends ConsumerStatefulWidget {
  const CoursPage({super.key});

  @override
  ConsumerState<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends ConsumerState<CoursPage> {
  int _currentIndex = 0;
  int _currentMatierePage = 0;
  final PageController _pageController = PageController();
  String? _previousUserId; // Pour détecter les changements d'utilisateur

  @override
  void initState() {
    super.initState();
    // Écouter les changements de l'utilisateur connecté pour charger/vider les matières
    // et traiter l'état initial.
    _setupUserListener();
  }

  void _setupUserListener() {
    // Traiter l'état actuel de l'utilisateur au démarrage de la page
    final currentUser = ref.read(currentUserProvider);
    _processCurrentUser(currentUser);
    _previousUserId = currentUser?.uid;

    // Écouter les changements futurs de l'utilisateur
    ref.listen<UserModel?>(currentUserProvider, (previous, next) {
      if (next?.uid != _previousUserId) { // Agir seulement si l'UID de l'utilisateur change
         _processCurrentUser(next);
         _previousUserId = next?.uid;
      }
    });
  }

  void _processCurrentUser(UserModel? currentUser) {
    final matiereNotifier = ref.read(matiereProvider.notifier);
    if (currentUser != null && 
        currentUser.role == 'etudiant' && 
        currentUser.niveauCode != null && 
        currentUser.serieCode != null) {
      // S'assurer que niveauCode et serieCode ne sont pas vides non plus
      if (currentUser.niveauCode!.isNotEmpty && currentUser.serieCode!.isNotEmpty) {
        matiereNotifier.fetchMatieres(
          niveauCode: currentUser.niveauCode!,
          serieCode: currentUser.serieCode!,
        );
      } else {
        matiereNotifier.clearDataAndError();
        matiereNotifier.setExternalError("Informations de niveau/série incomplètes.");
      }
    } else {
      matiereNotifier.clearDataAndError();
      if (currentUser == null) {
        // Optionnel: afficher un message spécifique si non connecté
        // matiereNotifier.setExternalError("Veuillez vous connecter pour voir vos matières.");
      } else if (currentUser.role != 'etudiant') {
         matiereNotifier.setExternalError("Cette section est réservée aux étudiants.");
      } else {
        // Pour le cas où niveauCode ou serieCode sont null malgré le rôle étudiant (devrait être empêché par la logique d'inscription)
        matiereNotifier.setExternalError("Informations de niveau/série manquantes pour charger les cours.");
      }
    }
  }

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
    final matiereState = ref.watch(matiereProvider);
    final List<MatiereModel> matieres = matiereState.matieres;
    final currentUser = ref.watch(currentUserProvider); // Pour afficher le titre dynamiquement

    String pageTitle = 'Cours';
    if (currentUser != null && currentUser.role == 'etudiant') {
      pageTitle = 'Mes Matières';
    }

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
        title: Text(pageTitle, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24)),
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
                  Container( // Welcome Banner
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser != null && currentUser.prenom != null && currentUser.prenom!.isNotEmpty
                                 ? 'Bienvenue ${currentUser.prenom} !' 
                                 : 'Bienvenue dans vos cours !',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
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
                  // Le titre est maintenant géré par l'AppBar, cette section est pour le contenu des matières
                  // const Text('Matières disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  // const SizedBox(height: 16),
                  
                  _buildMatiereContent(matiereState, matieres, currentUser),

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

  Widget _buildMatiereContent(MatiereState matiereState, List<MatiereModel> matieres, UserModel? currentUser) {
    if (currentUser == null) {
       return const Center(child: Text("Veuillez vous connecter pour accéder à vos matières."));
    }
    if (currentUser.role != 'etudiant') {
      return const Center(child: Text("Cette section est réservée aux étudiants."));
    }
    if (currentUser.niveauCode == null || currentUser.niveauCode!.isEmpty || 
        currentUser.serieCode == null || currentUser.serieCode!.isEmpty) {
      return const Center(child: Text("Informations de niveau/série manquantes. Veuillez compléter votre profil."));
    }

    if (matiereState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (matiereState.errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Erreur: ${matiereState.errorMessage}', style: const TextStyle(color: Colors.red)),
      ));
    }
    if (matieres.isEmpty) {
      return const Center(child: Text('Aucune matière trouvée pour votre niveau et série.'));
    }

    return Column(
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
            itemCount: (matieres.length / 4).ceil(),
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
                    if (itemIndex < matieres.length) {
                      final matiereModel = matieres[itemIndex];
                      return _buildMatiereCard(matiereModel);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20.0),
        if (matieres.isNotEmpty && (matieres.length / 4).ceil() > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate((matieres.length / 4).ceil(), (index) {
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
    );
  }

  Widget _buildMatiereCard(MatiereModel matiere) {
    return InkWell(
      onTap: () {
        context.push('/student/matieres/${matiere.id}', extra: matiere);
      },
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: _hexToColor(matiere.couleur).withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                   color: _hexToColor(matiere.couleur),
                   shape: BoxShape.circle,
                ),
                child: Icon(
                  _stringToIconData(matiere.icone),
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                matiere.nom,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _hexToColor(matiere.couleur).darken(0.3),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursRecents() {
    // TODO: Adapter cette section pour afficher les cours récents dynamiquement
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Iconsax.video_play, color: Colors.blueAccent, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Introduction à l\'algèbre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Mathématiques - Chapitre 1', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Icon(Iconsax.arrow_right_3, color: Colors.grey),
        ],
      ),
    );
  }
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
