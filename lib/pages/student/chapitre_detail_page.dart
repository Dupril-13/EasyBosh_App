// lib/pages/student/chapitre_detail_page.dart
import 'package:flutter/material.dart';
import '../../models/matiere_model.dart';
import 'lecon_detail_page.dart';

class ChapitreDetailPage extends StatefulWidget {
  final MatiereModel matiere;
  final ChapitreModel chapitre;

  const ChapitreDetailPage({
    super.key,
    required this.matiere,
    required this.chapitre,
  });

  @override
  State<ChapitreDetailPage> createState() => _ChapitreDetailPageState();
}

class _ChapitreDetailPageState extends State<ChapitreDetailPage> {
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
          widget.chapitre.nom,
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
            // En-tête du chapitre
            _buildChapitreHeader(),
            const SizedBox(height: 24),

            // Statistiques du chapitre
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Breadcrumb
            _buildBreadcrumb(),
            const SizedBox(height: 16),

            // Liste des leçons
            const Text(
              'Leçons',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Liste des leçons (design V1)
            _buildLeconsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChapitreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.chapitre.color, widget.chapitre.color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.chapitre.icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chapitre.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.matiere.nom,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.chapitre.difficulte,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.chapitre.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Barre de progression dans l'en-tête
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression du chapitre',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(widget.chapitre.progression * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.chapitre.progression,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final leconsCompletes = widget.chapitre.lecons.where((l) => l.estComplete).length;
    final tempsTotalMinutes = widget.chapitre.lecons.fold(0, (sum, l) => sum + l.dureeEstimeeMinutes);
    final heures = tempsTotalMinutes ~/ 60;
    final minutes = tempsTotalMinutes % 60;
    final tempsTotal = heures > 0 ? '${heures}h${minutes}min' : '${minutes}min';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Leçons',
            '${widget.chapitre.nombreLecons}',
            Icons.article_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Terminées',
            '$leconsCompletes',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Durée',
            tempsTotal,
            Icons.schedule,
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
              fontSize: 18,
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

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.home, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            widget.matiere.nom,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          Text(
            widget.chapitre.nom,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeconsList() {
    // Tri des leçons par ordre
    final leconsTriees = List<LeconModel>.from(widget.chapitre.lecons);
    leconsTriees.sort((a, b) => a.ordre.compareTo(b.ordre));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leconsTriees.length,
      itemBuilder: (context, index) {
        final lecon = leconsTriees[index];
        final estPrecedenteComplete = index == 0 || leconsTriees[index - 1].estComplete;
        final estAccessible = estPrecedenteComplete || lecon.estComplete;

        return _buildLeconCard(lecon, index + 1, estAccessible);
      },
    );
  }

  Widget _buildLeconCard(LeconModel lecon, int numero, bool estAccessible) {
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
          onTap: estAccessible ? () {
            // Navigation vers la page de la leçon
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeconDetailPage(
                  matiere: widget.matiere,
                  chapitre: widget.chapitre,
                  lecon: lecon,
                ),
              ),
            );
          } : null,
          child: Opacity(
            opacity: estAccessible ? 1.0 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Numéro de la leçon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: lecon.estComplete
                          ? Colors.green
                          : estAccessible
                          ? lecon.typeColor.withOpacity(0.1)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: lecon.estComplete
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                        '$numero',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: estAccessible ? lecon.typeColor : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Contenu de la leçon
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              lecon.typeIcon,
                              size: 18,
                              color: estAccessible ? lecon.typeColor : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lecon.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: estAccessible ? lecon.typeColor : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecon.titre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: estAccessible ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecon.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: estAccessible ? Colors.grey[600] : Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lecon.dureeEstimeeTexte,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (lecon.estComplete) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Terminée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Indicateur d'accès
                  Icon(
                    estAccessible
                        ? Icons.arrow_forward_ios
                        : Icons.lock_outline,
                    size: 16,
                    color: estAccessible ? Colors.grey[400] : Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}