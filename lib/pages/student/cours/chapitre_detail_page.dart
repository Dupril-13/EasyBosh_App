import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import '../../../models/chapitre_model.dart';
import '../../../models/lecon_model.dart';
import '../../../providers/lecon_provider.dart';
import '../../../providers/recent_lecons_provider.dart'; 
import '../../student/cours/lecon_detail_page.dart';
import '../../common/pdf_viewer_page.dart';
import '../../common/video_player_page.dart';
import '../../common/audio_player_page.dart'; // Réactivé
// import '../../../widgets/common/compact_audio_player.dart'; // Commenté

Color _hexToColorChapitre(String? hexString, {Color defaultColor = Colors.teal}) {
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

IconData _stringToIconDataChapitre(String? iconName, {IconData defaultIcon = Icons.class_outlined}) {
  if (iconName == null) return defaultIcon;
  return defaultIcon;
}

class ChapitreDetailPage extends ConsumerStatefulWidget {
  final MatiereModel matiere;
  final ChapitreModel chapitre;

  const ChapitreDetailPage({
    super.key,
    required this.matiere,
    required this.chapitre,
  });

  @override
  ConsumerState<ChapitreDetailPage> createState() => _ChapitreDetailPageState();
}

class _ChapitreDetailPageState extends ConsumerState<ChapitreDetailPage> {
  String _selectedLeconType = 'pdf'; 
  final List<String> _chipTypes = ['pdf', 'video', 'audio'];
  Map<String, int> _lessonsCountsPerType = {};
  List<LeconModel> _leconsAffichees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndProcessLecons();
    });
  }
  
  @override
  void didUpdateWidget(covariant ChapitreDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapitre.id != widget.chapitre.id) {
      setState(() {
        _selectedLeconType = 'pdf'; 
        _lessonsCountsPerType = {};
        _leconsAffichees = [];
      });
      _fetchDataAndProcessLecons();
    }
  }

  Future<void> _fetchDataAndProcessLecons() async {
    if (!mounted) return;
    await ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitre.id);
    if (mounted) {
      _processLecons();
    }
  }

  void _processLecons() {
    if (!mounted) return;
    final leconState = ref.read(leconProvider);
    final allLeconsForChapter = List<LeconModel>.from(leconState.lecons)
        .where((lecon) => lecon.actif == true) 
        .toList();

    Map<String, int> counts = {};
    for (String type in _chipTypes) {
      counts[type] = allLeconsForChapter.where((lecon) => lecon.type.toLowerCase() == type).length;
    }

    List<LeconModel> filtered = allLeconsForChapter
        .where((lecon) => lecon.type.toLowerCase() == _selectedLeconType)
        .toList();

    filtered.sort((a, b) {
      final orderA = a.ordreParType?[_selectedLeconType];
      final orderB = b.ordreParType?[_selectedLeconType];
      if (orderA != null && orderB != null) return orderA.compareTo(orderB);
      if (orderA != null) return -1;
      if (orderB != null) return 1;
      return a.ordre.compareTo(b.ordre);
    });
    
    setState(() {
      _lessonsCountsPerType = counts;
      _leconsAffichees = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leconState = ref.watch(leconProvider);
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
          widget.chapitre.nom,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChapitreHeader(),
            const SizedBox(height: 24),
            _buildBreadcrumb(),
            const SizedBox(height: 24),
            _buildFilterChips(),
            const SizedBox(height: 16),
            const Text('Leçons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            _buildLeconsList(leconState), 
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
     if (_lessonsCountsPerType.values.every((count) => count == 0) && _chipTypes.every((type) => (_lessonsCountsPerType[type] ?? 0) == 0)) {
        return const SizedBox.shrink();
    }
    return Container(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chipTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _chipTypes[index];
          final count = _lessonsCountsPerType[type] ?? 0;
          final bool isEnabled = count > 0;
          final bool isSelected = _selectedLeconType == type;
          return ChoiceChip(
            label: Text('${type.toUpperCase()} ($count)'),
            selected: isSelected,
            backgroundColor: Colors.grey[200],
            selectedColor: Theme.of(context).primaryColor,
            disabledColor: Colors.grey[300]?.withOpacity(0.5),
            labelStyle: TextStyle(color: isSelected ? Colors.white : (isEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[500])),
            shape: StadiumBorder(side: BorderSide(color: Colors.grey[300]!)),
            showCheckmark: false,
            onSelected: isEnabled
                ? (bool selected) {
                    if (selected) {
                      setState(() => _selectedLeconType = type);
                      _processLecons();
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

 Widget _buildLeconsList(LeconState leconState) {
    if (leconState.isLoading && _leconsAffichees.isEmpty && _lessonsCountsPerType.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (leconState.errorMessage != null && _leconsAffichees.isEmpty && _lessonsCountsPerType.values.every((c) => c ==0)) {
      return Center(child: Text('Erreur: ${leconState.errorMessage}'));
    }
    if (_leconsAffichees.isEmpty && (_lessonsCountsPerType[_selectedLeconType] ?? 0) == 0 && _chipTypes.contains(_selectedLeconType)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Aucune leçon de type "${_selectedLeconType.toUpperCase()}" pour ce chapitre pour le moment.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ),
      );
    }
    if (_leconsAffichees.isEmpty && !leconState.isLoading) {
        return const Center(
            child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Aucune leçon disponible pour ce chapitre pour le moment.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16))),
        );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _leconsAffichees.length,
      itemBuilder: (context, index) {
        final lecon = _leconsAffichees[index];
        final bool estAccessible = true; 
        int displayNumero = index + 1; 
        return _buildLeconCard(lecon, displayNumero, estAccessible);
      },
    );
  }

  Widget _buildChapitreHeader() {
    final Color placeholderColor = widget.matiere.couleur != null 
        ? _hexToColorChapitre(widget.matiere.couleur)
        : Colors.deepPurple;
    final IconData placeholderIcon = widget.matiere.icone != null
        ? _stringToIconDataChapitre(widget.matiere.icone)
        : Icons.library_books; 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [placeholderColor, placeholderColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(placeholderIcon, size: 32, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.chapitre.nom, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.matiere.nom, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
            ])),
            if (widget.chapitre.niveauCode != null)
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(widget.chapitre.niveauCode!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 16),
          Text(widget.chapitre.description ?? 'Aucune description pour ce chapitre.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Row(children: [
        Icon(Icons.home_outlined, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(widget.matiere.nom, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
        Expanded(child: Text(widget.chapitre.nom, style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildLeconCard(LeconModel lecon, int numero, bool estAccessible) {
    final Color typeColor = _getColorForLeconType(lecon.type);
    final IconData typeIcon = _getIconForLeconType(lecon.type);
    final String dureeTexte = lecon.dureeEstimee != null ? '${lecon.dureeEstimee} min' : 'N/A';
    final String typeDisplay = lecon.type.replaceAll('_', ' ').toUpperCase();
    final bool estCompletePlaceholder = false; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: estAccessible ? () {
            ref.read(recentLeconsProvider.notifier).markLeconAsViewed(lecon.id);
            if (lecon.type == 'pdf' && lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerPage(pdfUrl: lecon.urlMedia!, lessonTitle: lecon.nom)));
            } else if (lecon.type == 'video' && lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerPage(videoUrl: lecon.urlMedia!, lessonTitle: lecon.nom)));
            } else if (lecon.type == 'audio' && lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
               Navigator.push( // RESTAURÉ: Navigation vers AudioPlayerPage
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPlayerPage(
                    audioUrl: lecon.urlMedia!,
                    lessonTitle: lecon.nom,
                  ),
                ),
              );
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LeconDetailPage(matiere: widget.matiere, chapitre: widget.chapitre, lecon: lecon)));
            }
          } : null,
          child: Opacity(
            opacity: estAccessible ? 1.0 : 0.5,
            child: Padding( // Structure de la carte originale
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: estCompletePlaceholder ? Colors.green.withOpacity(0.1) : estAccessible ? typeColor.withOpacity(0.1) : Colors.grey[200], shape: BoxShape.circle),
                    child: Center(child: estCompletePlaceholder ? const Icon(Icons.check_circle, color: Colors.green, size: 22) : Text('$numero', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: estAccessible ? typeColor : Colors.grey[500]))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(typeIcon, size: 18, color: estAccessible ? typeColor : Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(typeDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: estAccessible ? typeColor : Colors.grey[500])),
                    ]),
                    const SizedBox(height: 4),
                    Text(lecon.nom, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: estAccessible ? Colors.black87 : Colors.grey[700])),
                    const SizedBox(height: 4),
                    if (lecon.description != null && lecon.description!.isNotEmpty)
                      Text(lecon.description!, style: TextStyle(fontSize: 14, color: estAccessible ? Colors.grey[600] : Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (lecon.description != null && lecon.description!.isNotEmpty) const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.schedule_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(dureeTexte, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ]),
                  ])),
                  Icon(estAccessible ? Icons.arrow_forward_ios : Icons.lock_outline, size: 16, color: estAccessible ? Colors.grey[400] : Colors.grey[500]), // Flèche restaurée
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForLeconType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf': return Colors.red.shade700;
      case 'video': return Colors.blue.shade700;
      case 'audio': return Colors.amber.shade700;
      case 'text_rich': return Colors.green.shade700;
      case 'quiz_ref': return Colors.purple.shade700;
      case 'image': return Colors.orange.shade700;
      default: return Colors.grey.shade700;
    }
  }

  IconData _getIconForLeconType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'video': return Icons.play_circle_outline;
      case 'audio': return Icons.audiotrack_outlined;
      case 'text_rich': return Icons.article_outlined;
      case 'quiz_ref': return Icons.quiz_outlined;
      case 'image': return Icons.image_outlined;
      default: return Icons.help_outline;
    }
  }
}
