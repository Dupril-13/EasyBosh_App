import 'package:flutter/material.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import '../../../models/chapitre_model.dart'; // Ajouté
// import '../../../models/lecon_model.dart'; // Pas directement utilisé ici, mais pour info
import '../cours/chapitre_detail_page.dart';

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
  // Ceci est un placeholder. Une vraie implémentation nécessiterait un map ou une logique plus robuste.
  // Exemples basés sur les noms utilisés dans cours_page.dart
  if (iconName == 'functions') return Icons.functions;
  if (iconName == 'science') return Icons.science;
  if (iconName == 'science_outlined') return Icons.science_outlined;
  if (iconName == 'menu_book') return Icons.menu_book;
  if (iconName == 'language') return Icons.language;
  // ... ajouter d'autres icônes si nécessaire
  return defaultIcon;
}

class MatiereDetailPage extends StatefulWidget {
  final MatiereModel matiere;

  const MatiereDetailPage({
    super.key,
    required this.matiere,
  });

  @override
  State<MatiereDetailPage> createState() => _MatiereDetailPageState();
}

class _MatiereDetailPageState extends State<MatiereDetailPage> {

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
                // nombreChapitres, niveaux ne sont pas dans MatiereModel
                // Utilisation de placeholders pour l'instant
                Text(
                  '0 chapitres disponibles', // Placeholder
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Text(
                //   'Niveau : N/A', // Placeholder
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.9),
                //     fontSize: 14,
                //   ),
                // ),
                // const SizedBox(height: 8),
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
    // nombreChapitres, nombreLecons, progressionMoyenne ne sont pas dans MatiereModel
    // Utilisation de placeholders
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Chapitres',
            '0', // Placeholder
            Icons.book_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Leçons',
            '0', // Placeholder
            Icons.article_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avancée',
            '0%', // Placeholder
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
    // widget.matiere.chapitres n'existe pas dans le MatiereModel actuel.
    // Pour l'instant, on affiche une liste vide ou un message.
    // Une vraie implémentation nécessiterait de fetcher les chapitres pour cette matière.
    final List<ChapitreModel> chapitres = []; // Placeholder: liste vide

    if (chapitres.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Aucun chapitre disponible pour cette matière pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapitres.length,
      itemBuilder: (context, index) {
        final chapitre = chapitres[index];
        return _buildChapitreCard(chapitre);
      },
    );
  }

  Widget _buildChapitreCard(ChapitreModel chapitre) {
    // Les champs comme color, icon, difficulte, progression, etc. n'existent pas dans notre ChapitreModel actuel.
    // Nous utilisons des placeholders ou des valeurs par défaut.
    final Color chapitrePlaceholderColor = Colors.teal;
    final IconData chapitrePlaceholderIcon = Icons.class_outlined; // Corrigé ici

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapitreDetailPage(
                  matiere: widget.matiere, // Corrigé ici
                  chapitre: chapitre, 
                ),
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
                    // Section "Difficulté" commentée car non présente dans ChapitreModel
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: chapitrePlaceholderColor.withOpacity(0.1), // Placeholder
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Text(
                    //     'Moyen', // Placeholder
                    //     style: TextStyle(
                    //       fontSize: 12,
                    //       color: chapitrePlaceholderColor, // Placeholder
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informations détaillées (nombreLecons, dureeEstimeeTexte) commentées
                // Row(
                //   children: [
                //     _buildInfoChip(
                //       Icons.article_outlined,
                //       '0 leçons', // Placeholder
                //       Colors.blue,
                //     ),
                //     const SizedBox(width: 12),
                //     _buildInfoChip(
                //       Icons.schedule,
                //       'N/A', // Placeholder
                //       Colors.green,
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),
                // Barre de progression commentée
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         Text(
                //           'Progression',
                //           style: TextStyle(
                //             fontSize: 14,
                //             fontWeight: FontWeight.w500,
                //             color: Colors.grey[700],
                //           ),
                //         ),
                //         Text(
                //           '0%', // Placeholder
                //           style: TextStyle(
                //             fontSize: 14,
                //             fontWeight: FontWeight.bold,
                //             color: chapitrePlaceholderColor, // Placeholder
                //           ),
                //         ),
                //       ],
                //     ),
                //     const SizedBox(height: 8),
                //     ClipRRect(
                //       borderRadius: BorderRadius.circular(4),
                //       child: LinearProgressIndicator(
                //         value: 0.0, // Placeholder
                //         backgroundColor: Colors.grey[300],
                //         valueColor: AlwaysStoppedAnimation<Color>(chapitrePlaceholderColor), // Placeholder
                //         minHeight: 6,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildInfoChip est commenté car les sections l'utilisant sont commentées
  // Widget _buildInfoChip(IconData icone, String texte, Color couleur) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: couleur.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icone, size: 14, color: couleur),
  //         const SizedBox(width: 4),
  //         Text(
  //           texte,
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: couleur,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
