// lib/pages/student/lecon_detail_page.dart
import 'package:flutter/material.dart';
import 'package:easybosh_v2/models/matiere_model.dart';

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
  bool _estComplete = false;

  @override
  void initState() {
    super.initState();
    _estComplete = widget.lecon.estComplete;
  }

  void _toggleComplete() {
    setState(() {
      _estComplete = !_estComplete;
    });

    // TODO: Sauvegarder l'état dans Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _estComplete
              ? 'Leçon marquée comme terminée !'
              : 'Leçon marquée comme non terminée',
        ),
        backgroundColor: _estComplete ? Colors.green : Colors.orange,
      ),
    );
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
          widget.lecon.titre,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _estComplete ? Icons.check_circle : Icons.check_circle_outline,
              color: _estComplete ? Colors.green : Colors.grey[600],
            ),
            onPressed: _toggleComplete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la leçon
            _buildLeconHeader(),

            // Contenu principal
            _buildLeconContent(),

            // Navigation entre leçons
            _buildNavigationSection(),

            const SizedBox(height: 100), // Espace pour le bouton flottant
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleComplete,
        icon: Icon(_estComplete ? Icons.refresh : Icons.check),
        label: Text(_estComplete ? 'Revoir' : 'Terminer'),
        backgroundColor: _estComplete ? Colors.orange : Colors.green,
      ),
    );
  }

  Widget _buildLeconHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.lecon.typeColor, widget.lecon.typeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              Icon(Icons.home, size: 14, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                '${widget.matiere.nom} / ${widget.chapitre.nom}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Titre et type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.lecon.typeIcon,
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
                      widget.lecon.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lecon.titre,
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

          // Description
          Text(
            widget.lecon.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Informations
          Row(
            children: [
              _buildHeaderInfo(Icons.schedule, widget.lecon.dureeEstimeeTexte),
              const SizedBox(width: 16),
              if (_estComplete)
                _buildHeaderInfo(Icons.check_circle, 'Terminée'),
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
          // Type de contenu spécifique
          if (widget.lecon.type == 'video') _buildVideoContent(),
          if (widget.lecon.type == 'texte') _buildTextContent(),
          if (widget.lecon.type == 'interactive') _buildInteractiveContent(),
          if (widget.lecon.type == 'quiz') _buildQuizContent(),

          const SizedBox(height: 20),

          // Contenu principal (markdown/html simulé)
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Lecteur vidéo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '(À implémenter)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, size: 20, color: widget.lecon.typeColor),
            const SizedBox(width: 8),
            Text(
              'Contenu textuel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.lecon.typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInteractiveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app, size: 20, color: widget.lecon.typeColor),
            const SizedBox(width: 8),
            Text(
              'Contenu interactif',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.lecon.typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.lecon.typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.lecon.typeColor.withOpacity(0.3)),
          ),
          child: const Column(
            children: [
              Icon(Icons.touch_app, size: 32),
              SizedBox(height: 8),
              Text(
                'Exercice interactif',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'À implémenter',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz_outlined, size: 20, color: widget.lecon.typeColor),
            const SizedBox(width: 8),
            Text(
              'Quiz intégré',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.lecon.typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz à implémenter')),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Commencer le quiz'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.lecon.typeColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMainContent() {
    // Simulation du contenu markdown/html
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
        Text(
          widget.lecon.contenu.isNotEmpty
              ? widget.lecon.contenu
              : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection() {
    // Trouver les leçons précédente et suivante
    final toutesLecons = List<LeconModel>.from(widget.chapitre.lecons);
    toutesLecons.sort((a, b) => a.ordre.compareTo(b.ordre));

    final indexActuel = toutesLecons.indexWhere((l) => l.id == widget.lecon.id);
    final leconPrecedente = indexActuel > 0 ? toutesLecons[indexActuel - 1] : null;
    final leconSuivante = indexActuel < toutesLecons.length - 1 ? toutesLecons[indexActuel + 1] : null;

    if (leconPrecedente == null && leconSuivante == null) {
      return const SizedBox.shrink();
    }

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
          const Text(
            'Navigation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Leçon précédente
              if (leconPrecedente != null)
                Expanded(
                  child: _buildNavigationButton(
                    leconPrecedente,
                    'Précédente',
                    Icons.arrow_back,
                    true,
                  ),
                ),
              if (leconPrecedente != null && leconSuivante != null)
                const SizedBox(width: 16),
              // Leçon suivante
              if (leconSuivante != null)
                Expanded(
                  child: _buildNavigationButton(
                    leconSuivante,
                    'Suivante',
                    Icons.arrow_forward,
                    false,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Bouton retour au chapitre
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.list),
              label: Text('Retour au chapitre "${widget.chapitre.nom}"'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(LeconModel lecon, String direction, IconData icon, bool isPrevious) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LeconDetailPage(
                matiere: widget.matiere,
                chapitre: widget.chapitre,
                lecon: lecon,
              ),
            ),
          );
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
                  if (isPrevious) ...[
                    Icon(icon, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    direction,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isPrevious) ...[
                    const SizedBox(width: 4),
                    Icon(icon, size: 16, color: Colors.grey[600]),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    lecon.typeIcon,
                    size: 16,
                    color: lecon.typeColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lecon.titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isPrevious ? TextAlign.start : TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lecon.dureeEstimeeTexte,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: isPrevious ? TextAlign.start : TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
