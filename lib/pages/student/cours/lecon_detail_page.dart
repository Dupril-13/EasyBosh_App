import 'package:flutter/material.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import '../../../models/chapitre_model.dart'; 
import '../../../models/lecon_model.dart';   
import 'package:iconsax_flutter/iconsax_flutter.dart'; 

Color _getLeconTypeColor(String? type, {Color defaultColor = Colors.blue}) {
  switch (type?.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade700;
      case 'video':
        return Colors.blue.shade700;
      case 'audio': 
        return Colors.amber.shade700;
      case 'text_rich':
      case 'texte':
        return Colors.green.shade700;
      case 'quiz_ref':
      case 'quiz':
        return Colors.purple.shade700;
      case 'image':
        return Colors.orange.shade700;
      case 'interactive':
        return Colors.teal.shade700;
      default:
        return defaultColor;
    }
}

IconData _getLeconTypeIcon(String? type, {IconData defaultIcon = Iconsax.document_text}) { 
  switch (type?.toLowerCase()) {
      case 'pdf':
        return Iconsax.document; // Corrigé: Remplacé document_pdf par document
      case 'video':
        return Iconsax.video_play;
      case 'audio':
        return Iconsax.audio_square;
      case 'text_rich':
      case 'texte':
        return Iconsax.document_text_1;
      case 'quiz_ref':
      case 'quiz':
        return Iconsax.message_question;
      case 'image':
        return Iconsax.gallery;
      case 'interactive':
        return Iconsax.bezier; 
      default:
        return defaultIcon;
    }
}

class LeconDetailPage extends StatefulWidget {
  final MatiereModel matiere;     
  final ChapitreModel chapitre; 
  final LeconModel lecon;       

  const LeconDetailPage({
    super.key,
    required this.matiere,
    required this.chapitre,
    required this.lecon,
  });

  @override
  State<LeconDetailPage> createState() => _LeconDetailPageState();
}

class _LeconDetailPageState extends State<LeconDetailPage> {
  bool _estCompleteLocal = false; 

  @override
  void initState() {
    super.initState();
    _estCompleteLocal = false; 
  }

  void _toggleComplete() {
    setState(() {
      _estCompleteLocal = !_estCompleteLocal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _estCompleteLocal
              ? 'Leçon marquée comme terminée !'
              : 'Leçon marquée comme non terminée.',
        ),
        backgroundColor: _estCompleteLocal ? Colors.green.shade600 : Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0, 
            floating: false,
            pinned: true,
            backgroundColor: leconColor, 
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _estCompleteLocal ? Iconsax.task_square : Iconsax.add_square, 
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: _toggleComplete,
                tooltip: _estCompleteLocal ? 'Marquer comme non terminée' : 'Marquer comme terminée',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(left: 50, right: 50, bottom: 16),
              title: Text(
                widget.lecon.nom, 
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              background: _buildLeconHeaderBackground(leconColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top:8.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeconContentCard(),
                  _buildNavigationSection(),
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleComplete,
        icon: Icon(_estCompleteLocal ? Iconsax.refresh : Iconsax.tick_circle, color: Colors.white), 
        label: Text(_estCompleteLocal ? 'Revoir Leçon' : 'Terminer Leçon', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _estCompleteLocal ? Colors.orange.shade600 : Colors.green.shade600,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLeconHeaderBackground(Color leconColor) {
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    final String dureeEstimText = widget.lecon.dureeEstimee != null 
        ? '${widget.lecon.dureeEstimee} min' 
        : 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [leconColor, leconColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Icon(leconIcon, size: 150, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 30 , 16, 50), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [
                Text(
                  '${widget.matiere.nom} / ${widget.chapitre.nom}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.lecon.description ?? 'Aucune description pour cette leçon.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 15,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildHeaderInfoChip(Iconsax.clock, dureeEstimText, Colors.white.withOpacity(0.25)), 
                    const SizedBox(width: 10),
                    if (_estCompleteLocal)
                      _buildHeaderInfoChip(Iconsax.verify, 'Terminée', Colors.white.withOpacity(0.35)), 
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoChip(IconData icon, String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeconContentCard() {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lecon.type?.toLowerCase() == 'video') _buildVideoContent(),
            if (widget.lecon.type?.toLowerCase() == 'pdf') _buildPdfContent(),
            if (widget.lecon.type?.toLowerCase() == 'texte' || widget.lecon.type?.toLowerCase() == 'text_rich') ...[
              _buildSectionTitle('Contenu principal', _getLeconTypeIcon(widget.lecon.type), _getLeconTypeColor(widget.lecon.type)),
              _buildMainContent()
            ],
            if (widget.lecon.type?.toLowerCase() == 'interactive') _buildInteractiveContent(),
            if (widget.lecon.type?.toLowerCase() == 'quiz' || widget.lecon.type?.toLowerCase() == 'quiz_ref') _buildQuizContent(), 
            
            if (!['video', 'pdf', 'texte', 'text_rich', 'interactive', 'quiz', 'quiz_ref'].contains(widget.lecon.type?.toLowerCase()))
              _buildMainContent(), 
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Text(
            title, 
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color, 
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildVideoContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vidéo', leconIcon, leconColor),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(leconIcon, size: 50, color: Colors.white70),
                  const SizedBox(height: 12),
                  if (widget.lecon.urlMedia != null)
                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.play_circle, color: Colors.white), 
                      label: const Text('Lancer la vidéo', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: leconColor.withOpacity(0.8), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      onPressed: () { 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lancement vidéo: ${widget.lecon.urlMedia}')));
                      },
                    )
                  else
                    Text('URL Média non fournie', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('(Lecteur vidéo à intégrer)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
         if(widget.lecon.contenu != null && widget.lecon.contenu!.containsKey('transcription'))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Transcription:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.lecon.contenu!['transcription'].toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))
            ],)
          )
      ],
    );
  }

  Widget _buildPdfContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Document PDF', leconIcon, leconColor),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: leconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: leconColor.withOpacity(0.3))
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(leconIcon, size: 50, color: leconColor),
              const SizedBox(height: 16),
              if (widget.lecon.urlMedia != null)
                ElevatedButton.icon(
                    icon: const Icon(Iconsax.document_download, color: Colors.white), 
                    label: const Text('Ouvrir le PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: leconColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    onPressed: () { 
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ouverture PDF: ${widget.lecon.urlMedia}')));
                    },
                  )
              else
                Text('URL PDF non fournie', style: TextStyle(color: leconColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('(Visualiseur PDF à intégrer)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInteractiveContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contenu Interactif', leconIcon, leconColor),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: leconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: leconColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(leconIcon, size: 40, color: leconColor,),
              const SizedBox(height: 12),
              Text(widget.lecon.contenu?['titre_interactif']?.toString() ?? 'Exercice interactif', 
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: leconColor)), 
              const SizedBox(height: 4),
              Text(widget.lecon.contenu?['instruction_interactif']?.toString() ?? 'Lancez l\'activité pour continuer.', 
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: (){}, child: const Text('Commencer l\'activité'), style: ElevatedButton.styleFrom(backgroundColor: leconColor, foregroundColor: Colors.white))
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quiz de Révision', leconIcon, leconColor),
        Text(widget.lecon.contenu?['description_quiz']?.toString() ?? 'Testez vos connaissances sur cette leçon.', 
          style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4)
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quiz ID: ${widget.lecon.contenu?['quiz_id']?.toString() ?? 'Non défini'} - Navigation/Logique Quiz à implémenter')),
              );
            },
            icon: const Icon(Iconsax.play, color: Colors.white), 
            label: Text(widget.lecon.contenu?['label_bouton_quiz']?.toString() ?? 'Commencer le quiz', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: leconColor, 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16)
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMainContent() {
    if (widget.lecon.contenu == null || widget.lecon.contenu!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Text(
            'Aucun contenu principal pour cette leçon.',
            style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String mainText = '';
    dynamic contentData = widget.lecon.contenu;

    if (contentData is Map) {
      if (contentData['text_body'] is String) {
        mainText = contentData['text_body'];
      } else if (contentData['body'] is String) {
        mainText = contentData['body'];
      } else if (contentData['html_content'] is String) {
        mainText = '''Contenu HTML (prévisualisation brute):
${contentData['html_content']}''';
      } else if (contentData['blocks'] is List) {
        mainText = 'Contenu structuré (blocs) disponible.\nAffichage détaillé à implémenter.\n';
        try {
          (contentData['blocks'] as List).forEach((block) {
              if(block is Map && block.containsKey('text')){
                  mainText += '\n• ${block['text']}';
              }
          });
        } catch(e){ /* ignore parsing errors for now */}
      } else {
        mainText = '''Données de contenu (structure non gérée):
${widget.lecon.contenu.toString()}''';
      }
    } else {
       mainText = '''Format de contenu inattendu:
${widget.lecon.contenu.toString()}''';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        mainText,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildNavigationSection() {
    LeconModel? leconPrecedente = null;
    LeconModel? leconSuivante = null;

    if (leconPrecedente == null && leconSuivante == null) {
       return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.arrow_left_2), 
              label: Text('Retour au chapitre "${widget.chapitre.nom}"'),
              style: OutlinedButton.styleFrom( 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (leconPrecedente != null)
            Expanded(child: _buildNavigationButton(leconPrecedente, 'Précédente', Iconsax.arrow_left_3, true)), 
          if (leconPrecedente != null && leconSuivante != null)
            const SizedBox(width: 16),
          if (leconSuivante != null)
            Expanded(child: _buildNavigationButton(leconSuivante, 'Suivante', Iconsax.arrow_right_3, false)), 
        ],
      ),
    );
  }

  Widget _buildNavigationButton(LeconModel lecon, String direction, IconData icon, bool isPrevious) {
    final Color leconNavColor = _getLeconTypeColor(lecon.type, defaultColor: Colors.grey.shade700);
    final IconData leconNavIcon = _getLeconTypeIcon(lecon.type, defaultIcon: Icons.help_outline);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigation vers "${lecon.nom}" (à implémenter).')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: isPrevious ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrevious) ...[ Icon(icon, size: 18, color: Colors.grey[700]), const SizedBox(width: 6) ],
                  Text(direction, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  if (!isPrevious) ...[ const SizedBox(width: 6), Icon(icon, size: 18, color: Colors.grey[700]) ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if(isPrevious) ...[Icon(leconNavIcon, size: 20, color: leconNavColor), const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      lecon.nom, 
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isPrevious ? TextAlign.start : TextAlign.end,
                    ),
                  ),
                  if(!isPrevious) ...[const SizedBox(width: 8), Icon(leconNavIcon, size: 20, color: leconNavColor)],
                ],
              ),
              const SizedBox(height: 4),
              if (lecon.dureeEstimee != null)
                Text(
                  '${lecon.dureeEstimee} min', 
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: isPrevious ? TextAlign.start : TextAlign.end,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
