import 'package:flutter/material.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import '../../../models/chapitre_model.dart'; // Notre ChapitreModel
import '../../../models/lecon_model.dart';   // Notre LeconModel

// Placeholders pour les couleurs et icônes de type de leçon (si LeconModel ne les a pas)
Color _getLeconTypeColor(String? type, {Color defaultColor = Colors.blue}) {
  // Logique placeholder, à adapter si LeconModel a un champ couleur ou une meilleure logique de type
  if (type == 'video') return Colors.redAccent;
  if (type == 'texte') return Colors.green;
  if (type == 'interactive') return Colors.purpleAccent;
  if (type == 'quiz') return Colors.orangeAccent;
  return defaultColor;
}

IconData _getLeconTypeIcon(String? type, {IconData defaultIcon = Icons.article}) {
  // Logique placeholder
  if (type == 'video') return Icons.videocam;
  if (type == 'texte') return Icons.article_outlined;
  if (type == 'interactive') return Icons.touch_app;
  if (type == 'quiz') return Icons.quiz;
  return defaultIcon;
}

class LeconDetailPage extends StatefulWidget {
  final MatiereModel matiere;     // Notre MatiereModel
  final ChapitreModel chapitre; // Notre ChapitreModel
  final LeconModel lecon;       // Notre LeconModel

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
  bool _estCompleteLocal = false; // État local, car LeconModel n'a pas 'estComplete'

  @override
  void initState() {
    super.initState();
    // Initialiser _estCompleteLocal, potentiellement depuis une source externe (BD) plus tard
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
              ? 'Leçon marquée comme terminée (localement) !'
              : 'Leçon marquée comme non terminée (localement)',
        ),
        backgroundColor: _estCompleteLocal ? Colors.green : Colors.orange,
      ),
    );
    // TODO: Sauvegarder l'état dans Supabase (progression utilisateur)
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
          widget.lecon.nom, // Changé de titre à nom
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _estCompleteLocal ? Icons.check_circle : Icons.check_circle_outline,
              color: _estCompleteLocal ? Colors.green : Colors.grey[600],
            ),
            onPressed: _toggleComplete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeconHeader(),
            _buildLeconContent(),
            _buildNavigationSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleComplete,
        icon: Icon(_estCompleteLocal ? Icons.refresh : Icons.check),
        label: Text(_estCompleteLocal ? 'Revoir' : 'Terminer'),
        backgroundColor: _estCompleteLocal ? Colors.orange : Colors.green,
      ),
    );
  }

  Widget _buildLeconHeader() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    final IconData leconIcon = _getLeconTypeIcon(widget.lecon.type);
    final String dureeEstimText = widget.lecon.dureeEstimee != null 
        ? '${widget.lecon.dureeEstimee} min' 
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [leconColor, leconColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, size: 14, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.matiere.nom} / ${widget.chapitre.nom}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  leconIcon, // Placeholder icon
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lecon.type.toUpperCase(), // From LeconModel
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lecon.nom, // From LeconModel
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.lecon.description ?? 'Pas de description pour cette leçon.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderInfo(Icons.schedule, dureeEstimText),
              const SizedBox(width: 16),
              if (_estCompleteLocal)
                _buildHeaderInfo(Icons.check_circle, 'Terminée (localement)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildLeconContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lecon.type == 'video') _buildVideoContent(),
          if (widget.lecon.type == 'texte') _buildTextContent(), // texte, text_rich etc.
          if (widget.lecon.type == 'interactive') _buildInteractiveContent(),
          if (widget.lecon.type == 'quiz') _buildQuizContent(), 
          // Add other types as needed

          const SizedBox(height: 20),
          _buildMainContent(),
        ],
      ),
    );
  }

 Widget _buildVideoContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ici, il faudrait un vrai lecteur vidéo qui utilise widget.lecon.urlMedia
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.lecon.urlMedia != null ? 'Vidéo à charger' : 'URL Média non fournie',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (widget.lecon.urlMedia != null) Text(widget.lecon.urlMedia!, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                const Text('(Lecteur vidéo à implémenter)', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, size: 20, color: leconColor), // Placeholder icon
            const SizedBox(width: 8),
            Text(
              'Contenu textuel', // Placeholder title
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: leconColor, // Placeholder color
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Le contenu principal sera géré par _buildMainContent
      ],
    );
  }

  Widget _buildInteractiveContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app, size: 20, color: leconColor), // Placeholder icon
            const SizedBox(width: 8),
            Text(
              'Contenu interactif', // Placeholder title
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: leconColor, // Placeholder color
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: leconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: leconColor.withOpacity(0.3)),
          ),
          child: const Column(
            children: [
              Icon(Icons.touch_app, size: 32), // Placeholder
              SizedBox(height: 8),
              Text('Exercice interactif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text('À implémenter', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizContent() {
    final Color leconColor = _getLeconTypeColor(widget.lecon.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz_outlined, size: 20, color: leconColor), // Placeholder icon
            const SizedBox(width: 8),
            Text(
              'Quiz intégré', // Placeholder title
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: leconColor, // Placeholder color
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz à implémenter (potentiellement via contenu JSONB)')),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Commencer le quiz'),
          style: ElevatedButton.styleFrom(
            backgroundColor: leconColor, // Placeholder color
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMainContent() {
    // widget.lecon.contenu est Map<String, dynamic>? dans notre LeconModel.
    // La V1 s'attendait à un String.
    // Pour la compilation, on affiche un placeholder.
    // Une vraie implémentation parserait le JSONB et construirait l'UI dynamiquement.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contenu de la leçon',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text(
            widget.lecon.contenu != null 
              ? 'Contenu JSONB disponible (affichage à implémenter): ${widget.lecon.contenu.toString().substring(0,widget.lecon.contenu.toString().length > 100 ? 100 : widget.lecon.contenu.toString().length)}...' 
              : 'Aucun contenu principal fourni pour cette leçon (ou format non String).',
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection() {
    // Notre ChapitreModel actuel ne contient pas de liste de leçons (`widget.chapitre.lecons`).
    // Cette liste doit être fetchée séparément (ex: via leconProvider).
    // Pour l'instant, la navigation sera désactivée.
    final List<LeconModel> toutesLecons = []; // Vide pour l'instant
    LeconModel? leconPrecedente = null;
    LeconModel? leconSuivante = null;

    // La logique suivante pour trouver prev/next ne fonctionnera pas sans `toutesLecons`
    // if (toutesLecons.isNotEmpty) {
    //   toutesLecons.sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
    //   final indexActuel = toutesLecons.indexWhere((l) => l.id == widget.lecon.id);
    //   if (indexActuel != -1) {
    //      leconPrecedente = indexActuel > 0 ? toutesLecons[indexActuel - 1] : null;
    //      leconSuivante = indexActuel < toutesLecons.length - 1 ? toutesLecons[indexActuel + 1] : null;
    //   }
    // }

    if (leconPrecedente == null && leconSuivante == null) {
      // Afficher au moins le bouton retour au chapitre si pas de navigation
       return Container(
          margin: const EdgeInsets.fromLTRB(16,32,16,16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4)) ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.list),
              label: Text('Retour au chapitre "${widget.chapitre.nom}"'),
              style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) ),
            ),
          ),
        );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (leconPrecedente != null) Expanded(child: _buildNavigationButton(leconPrecedente, 'Précédente', Icons.arrow_back, true)),
              if (leconPrecedente != null && leconSuivante != null) const SizedBox(width: 16),
              if (leconSuivante != null) Expanded(child: _buildNavigationButton(leconSuivante, 'Suivante', Icons.arrow_forward, false)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.list),
              label: Text('Retour au chapitre "${widget.chapitre.nom}"'),
              style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) ),
            ),
          ),
        ],
      ),
    );
  }

  // Ce bouton ne sera pas fonctionnel tant que `toutesLecons` n'est pas peuplé.
  // Les champs lecon.typeIcon, lecon.typeColor, lecon.titre, lecon.dureeEstimeeTexte sont des placeholders.
  Widget _buildNavigationButton(LeconModel lecon, String direction, IconData icon, bool isPrevious) {
    final Color leconNavColor = _getLeconTypeColor(lecon.type, defaultColor: Colors.grey.shade700);
    final IconData leconNavIcon = _getLeconTypeIcon(lecon.type, defaultIcon: Icons.help_outline);
    final String leconNavDuree = lecon.dureeEstimee != null ? '${lecon.dureeEstimee} min' : 'N/A';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => LeconDetailPage(
          //       matiere: widget.matiere,
          //       chapitre: widget.chapitre,
          //       lecon: lecon,
          //     ),
          //   ),
          // );
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigation désactivée (liste des leçons non chargée).')));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isPrevious ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: isPrevious ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  if (isPrevious) ...[ Icon(icon, size: 16, color: Colors.grey[600]), const SizedBox(width: 4) ],
                  Text(direction, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  if (!isPrevious) ...[ const SizedBox(width: 4), Icon(icon, size: 16, color: Colors.grey[600]) ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(leconNavIcon, size: 16, color: leconNavColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lecon.nom, // était lecon.titre
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isPrevious ? TextAlign.start : TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                leconNavDuree, // était lecon.dureeEstimeeTexte
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
