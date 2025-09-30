import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/user_model.dart'; 
import 'package:easybosh_v2/core/providers/auth_provider.dart'; 
import 'package:easybosh_v2/pages/student/cours/chapitre_detail_page.dart'; 
import 'package:easybosh_v2/providers/user_chapter_progress_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper to convert hex string to Color
Color _hexToColor(String? hexString, {Color defaultColor = Colors.grey}) {
  if (hexString == null) return defaultColor;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return defaultColor;
  }
}

// Placeholder to convert string to IconData (très basique)
IconData _stringToIconData(String? iconName, {IconData defaultIcon = Icons.help_outline}) {
  if (iconName == null) return defaultIcon;
  if (iconName == 'functions') return Icons.functions;
  if (iconName == 'science') return Icons.science;
  if (iconName == 'science_outlined') return Icons.science_outlined;
  if (iconName == 'menu_book') return Icons.menu_book;
  if (iconName == 'language') return Icons.language;
  return defaultIcon;
}

class MatiereDetailPage extends ConsumerStatefulWidget {
  final MatiereModel matiere;

  const MatiereDetailPage({
    super.key,
    required this.matiere,
  });

  @override
  ConsumerState<MatiereDetailPage> createState() => _MatiereDetailPageState();
}

class _MatiereDetailPageState extends ConsumerState<MatiereDetailPage> {
  List<ChapitreModel> _chapitres = [];
  bool _isLoadingChapitres = true;
  String? _errorLoadingChapitres;
  int _totalActiveLeconsCount = 0;
  bool _isLoadingLeconsCount = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingChapitres = true;
      _isLoadingLeconsCount = true;
      _errorLoadingChapitres = null;
      _chapitres = [];
      _totalActiveLeconsCount = 0;
    });

    final UserModel? currentUser = ref.read(currentUserProvider);
    String? userNiveauCode;
    String? userSerieCode;

    if (currentUser != null && currentUser.isEtudiant) {
      userNiveauCode = currentUser.niveauCode;
      userSerieCode = currentUser.serieCode;
    }

    try {
      // Fetch Chapitres
      var queryBuilder = Supabase.instance.client
          .from('chapitres')
          .select('id, nom, description, ordre, niveau_code, serie_code, created_at') // Added created_at
          .eq('matiere_id', widget.matiere.id)
          .eq('actif', true);

      if (userNiveauCode != null && userNiveauCode.isNotEmpty) {
        queryBuilder = queryBuilder.eq('niveau_code', userNiveauCode);
      } else if (currentUser != null && currentUser.isEtudiant) {
        debugPrint("[MatiereDetailPage] Etudiant ${currentUser.uid} n'a pas de niveau_code.");
         if (mounted) {
          setState(() {
            _isLoadingChapitres = false;
            _isLoadingLeconsCount = false;
            _errorLoadingChapitres = "Votre niveau n'est pas défini. Impossible de charger les données.";
          });
        }
        return; 
      }
      
      if (userNiveauCode == '3eme') {
         if (userSerieCode == null || userSerieCode.isEmpty) {
            queryBuilder = queryBuilder.filter('serie_code', 'is', 'null'); 
         } else {
            queryBuilder = queryBuilder.eq('serie_code', userSerieCode); 
         }
      } else if (userSerieCode != null && userSerieCode.isNotEmpty) {
         queryBuilder = queryBuilder.eq('serie_code', userSerieCode);
      } else if (currentUser != null && currentUser.isEtudiant && userNiveauCode != '3eme') {
         debugPrint("[MatiereDetailPage] Etudiant ${currentUser.uid} (niveau $userNiveauCode) n'a pas de serie_code.");
          if (mounted) {
            setState(() {
              _isLoadingChapitres = false;
              _isLoadingLeconsCount = false;
              _errorLoadingChapitres = "Votre série n'est pas définie. Impossible de charger les données.";
            });
          }
          return; 
      }

      final List<Map<String, dynamic>> chapitresResponseData = await queryBuilder.order('ordre', ascending: true);
      final fetchedChapitres = chapitresResponseData
          .map((itemAsMap) => ChapitreModel.fromMap(itemAsMap))
          .toList();

      if (mounted) {
        setState(() {
          _chapitres = fetchedChapitres;
          _isLoadingChapitres = false;
        });

        if (fetchedChapitres.isNotEmpty) {
          final chapitreIds = fetchedChapitres.map((c) => c.id).toList();
          // Fetch progress for these chapters
          await ref.read(userChapterProgressProvider.notifier).fetchProgressForChapters(chapitreIds);

          // Fetch active lecons count for these chapters
          try {
            final leconsCountResponse = await Supabase.instance.client
                .from('cours') 
                .select() 
                .eq('actif', true)
                .filter('chapitre_id', 'in', '(${chapitreIds.join(',')})')
                .count(CountOption.exact);
            
            if (mounted) {
              setState(() {
                _totalActiveLeconsCount = leconsCountResponse.count ?? 0;
                _isLoadingLeconsCount = false;
              });
            }
          } catch (e) {
            debugPrint('Erreur comptage leçons: $e');
            if (mounted) {
              setState(() {
                _isLoadingLeconsCount = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingLeconsCount = false;
              _totalActiveLeconsCount = 0;
            });
          }
        }
      }
    } on PostgrestException catch (e) {
      debugPrint('Erreur Supabase Postgrest (MatiereDetailPage): CODE ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorLoadingChapitres = 'Erreur BDD: ${e.message} (code: ${e.code})';
          _isLoadingChapitres = false;
          _isLoadingLeconsCount = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur générale (MatiereDetailPage): $e\n$stackTrace');
       if (mounted) {
        setState(() {
          _errorLoadingChapitres = 'Erreur inattendue: ${e.toString()}';
          _isLoadingChapitres = false;
          _isLoadingLeconsCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.matiere.nom,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatiereHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            const Text(
              'Chapitres',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildChapitresGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereHeader() {
    final Color matiereColor = _hexToColor(widget.matiere.couleur, defaultColor: Colors.blueAccent);
    final IconData matiereIcon = _stringToIconData(widget.matiere.icone, defaultIcon: Icons.school);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [matiereColor, matiereColor.withOpacity(0.7)],
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
                  widget.matiere.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoadingChapitres ? 'Chargement des chapitres...' : (_chapitres.isNotEmpty ? '${_chapitres.length} chapitres disponibles' : 'Aucun chapitre pour votre classe actuellement'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.matiere.description ?? 'Aucune description pour cette matière.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              matiereIcon,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final chapterProgressState = ref.watch(userChapterProgressProvider);
    int completedChaptersCount = chapterProgressState.progressMap.values.where((p) => p.isCompleted).length;
    double progressPercentage = _chapitres.isNotEmpty && !_isLoadingChapitres ? (completedChaptersCount / _chapitres.length) * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Chapitres',
            _isLoadingChapitres ? '-' : _chapitres.length.toString(),
            Icons.book_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Leçons',
            _isLoadingLeconsCount ? '-' : _totalActiveLeconsCount.toString(),
            Icons.article_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avancée',
             _isLoadingChapitres ? '-' : '${progressPercentage.toStringAsFixed(0)}%', 
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String titre, String valeur, IconData icone, Color couleur) {
    return Container(
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
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 24),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          Text(
            titre,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChapitresGrid() {
    if (_isLoadingChapitres) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLoadingChapitres != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorLoadingChapitres!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                onPressed: _fetchData, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              )
            ],
          ),
        ),
      );
    }

    if (_chapitres.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'Aucun chapitre disponible pour cette matière dans votre classe actuelle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chapitres.length,
      itemBuilder: (context, index) {
        final chapitre = _chapitres[index];
        return _buildChapitreCard(chapitre);
      },
    );
  }

  Widget _buildChapitreCard(ChapitreModel chapitre) {
    final Color chapitrePlaceholderColor = Colors.teal;
    final IconData chapitrePlaceholderIcon = Icons.class_outlined;
    
    final chapterProgressState = ref.watch(userChapterProgressProvider);
    final isCompleted = chapterProgressState.progressMap[chapitre.id]?.isCompleted ?? false;

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push<Widget>( 
              context,
              MaterialPageRoute(
                builder: (BuildContext context) { 
                  return ChapitreDetailPage(
                    matiere: widget.matiere,
                    chapitre: chapitre,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: chapitrePlaceholderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        chapitrePlaceholderIcon,
                        color: chapitrePlaceholderColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapitre.nom,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chapitre.description ?? 'Pas de description pour ce chapitre.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        color: isCompleted ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(userChapterProgressProvider.notifier).toggleChapterCompletion(chapitre.id, isCompleted);
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
