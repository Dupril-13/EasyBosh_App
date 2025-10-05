import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';
import 'package:easybosh_v2/models/user_model.dart';
import 'package:easybosh_v2/models/recent_lecon_info_model.dart';
import 'package:easybosh_v2/providers/recent_lecons_provider.dart';
import 'package:easybosh_v2/pages/student/cours/chapitre_detail_page.dart';
import '../../widgets/custom_navbar.dart';
import '../../models/matiere_model.dart';

Color _hexToColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return Colors.grey.shade300;
  }
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  if (hexColor.length == 8) {
    try {
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return Colors.grey.shade300;
    }
  }
  return Colors.grey.shade300;
}

IconData _stringToIconData(String? iconName) {
  if (iconName == null || iconName.isEmpty) {
    return Iconsax.book;
  }
  switch (iconName) {
    case 'functions': return Iconsax.calculator;
    case 'science': return Iconsax.activity;
    case 'science_outlined': return Iconsax.shapes;
    case 'menu_book': return Iconsax.book_1;
    case 'language': return Iconsax.language_square;
    case 'public': return Iconsax.global;
    case 'map': return Iconsax.map_1;
    case 'psychology': return Iconsax.profile_2user;
    case 'eco': return Iconsax.cpu_charge;
    case 'computer': return Iconsax.monitor;
    case 'gavel': return Iconsax.judge;
    case 'sports_soccer': return Iconsax.cup;
    case 'biotech_outlined': return Iconsax.microscope;
    case 'translate': return Iconsax.translate;
    case 'music_note': return Iconsax.music;
    case 'palette': return Iconsax.color_swatch;
    case 'theater_comedy': return Iconsax.happyemoji;
    case 'home_work': return Iconsax.home_hashtag;
    default:
      return Iconsax.book;
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
  final PageController _pageController = PageController(viewportFraction: 1.0);
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialUserCheck = ref.read(currentUserProvider);
        _processCurrentUser(initialUserCheck);
        _previousUserId = initialUserCheck?.uid;
      }
    });
  }

  void _processCurrentUser(UserModel? currentUser) {
    final matiereNotifier = ref.read(matiereProvider.notifier);
    final recentLeconsNotifier = ref.read(recentLeconsProvider.notifier);

    if (currentUser != null &&
        currentUser.role == 'student' &&
        currentUser.niveauCode != null &&
        (currentUser.niveauCode == '3eme' || (currentUser.serieCode != null && currentUser.serieCode!.isNotEmpty)) &&
        currentUser.niveauCode!.isNotEmpty) {
      matiereNotifier.fetchMatieres(
        niveauCode: currentUser.niveauCode!,
        serieCode: currentUser.serieCode,
      );
      recentLeconsNotifier.fetchRecentLecons();
    } else {
      matiereNotifier.clearDataAndError();
      recentLeconsNotifier.fetchRecentLecons();
      if (currentUser == null) {
        // No specific message if disconnected
      } else if (currentUser.role != 'student') {
        matiereNotifier.setExternalError("Cette section est réservée aux étudiants.");
      } else {
        matiereNotifier.setExternalError("Complétez votre profil (niveau/série).");
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
    ref.listen<UserModel?>(currentUserProvider, (previous, next) {
      if (mounted && (next?.uid != _previousUserId || (_previousUserId == null && next != null))) {
        _processCurrentUser(next);
        _previousUserId = next?.uid;
      }
    });

    final matiereState = ref.watch(matiereProvider);
    final List<MatiereModel> matieres = matiereState.matieres;
    final currentUser = ref.watch(currentUserProvider);
    final recentLeconsState = ref.watch(recentLeconsProvider);

    String pageTitle = 'Cours';
    if (currentUser != null && currentUser.role == 'student') {
      pageTitle = 'Mes Matières';
    }

    const double bottomPaddingForScroll = 30.0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Empêcher la sortie de l'app
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Iconsax.notification, color: Colors.grey[700]),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
          title: Text(pageTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Iconsax.setting_2, color: Colors.grey[700]),
              onPressed: () => context.push('/settings'),
              tooltip: 'Paramètres',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _processCurrentUser(ref.read(currentUserProvider));
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, bottomPaddingForScroll),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withAlpha(200)],
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
                              const Icon(Iconsax.teacher, size: 70, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("Matières disponibles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      const SizedBox(height: 16),
                      _buildMatiereContent(matiereState, matieres, currentUser),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Consultés récemment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCoursRecents(recentLeconsState.recentLecons, recentLeconsState.isLoading, recentLeconsState.errorMessage),
                      )
                    ],
                  ),
                ),
              ),
              CustomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 16.0),
          child: FloatingActionButton(
            onPressed: () => context.push('/chatbot'),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Iconsax.message_question, color: Colors.white),
            tooltip: 'EasyBot',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildMatiereContent(MatiereState matiereState, List<MatiereModel> matieres, UserModel? currentUser) {
    final bool isProfileError = matiereState.errorMessage?.contains("profil") ?? false;

    if (currentUser == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Veuillez vous connecter.", style: TextStyle(fontSize: 16, color: Colors.grey))));
    }
    if (currentUser.role != 'student') {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(matiereState.errorMessage ?? "Accès étudiant requis.", style: const TextStyle(fontSize: 16, color: Colors.redAccent))));
    }

    if (isProfileError) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(matiereState.errorMessage ?? "Veuillez compléter votre profil (niveau/série).", style: const TextStyle(fontSize: 16, color: Colors.orangeAccent))));
    }

    if (matiereState.isLoading && matieres.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }

    if (matiereState.errorMessage != null && matieres.isEmpty && !isProfileError) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('Erreur: ${matiereState.errorMessage}', style: const TextStyle(color: Colors.red, fontSize: 16))));
    }
    if (matieres.isEmpty && !matiereState.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Aucune matière pour votre sélection.', style: TextStyle(fontSize: 16, color: Colors.grey))));
    }

    final int pageCount = (matieres.length / 4).ceil();

    if (matieres.isEmpty) {
      return const SizedBox.shrink();
    }

    double cardsAreaHeight = 0;
    if (matieres.isNotEmpty) {
      cardsAreaHeight = matieres.length > 2 ? 396.0 : 190.0;
    }

    return Column(
      children: [
        SizedBox(
          height: cardsAreaHeight,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            onPageChanged: (index) {
              setState(() {
                _currentMatierePage = index;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentMatierePage == index ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildMatiereCard(MatiereModel matiere) {
    final Color cardColor = _hexToColor(matiere.couleur);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 190,
        maxHeight: 190,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.push('/student/cours/matiere/${matiere.id}', extra: matiere);
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
                      color: cardColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _stringToIconData(matiere.icone),
                      color: cardColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    matiere.nom,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explorer',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
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

  Widget _buildCoursRecents(List<RecentLeconInfoModel> leconsRecents, bool isLoading, String? errorMsg) {
    if (isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
    }

    if (errorMsg != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Erreur: $errorMsg", style: const TextStyle(color: Colors.red))));
    }

    if (leconsRecents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Aucune leçon récemment consultée.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: leconsRecents.map((recentInfo) {
        final Color matiereColor = _hexToColor(recentInfo.matiere.couleur);

        return GestureDetector(
          onTap: () {
            Navigator.push<Widget>(
              context,
              MaterialPageRoute(
                builder: (context) => ChapitreDetailPage(
                  matiere: recentInfo.matiere,
                  chapitre: recentInfo.chapitre,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
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
                  width: 6,
                  height: 50,
                  decoration: BoxDecoration(
                    color: matiereColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentInfo.lecon.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recentInfo.matiere.nom,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Iconsax.arrow_right_3, size: 20, color: matiereColor),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}