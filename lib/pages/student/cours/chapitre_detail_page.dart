import 'package:flutter/material.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import '../../../models/chapitre_model.dart'; // Assumed to be our new ChapitreModel
import '../../../models/lecon_model.dart';   // Import for our new LeconModel
import '../../student/cours/lecon_detail_page.dart';

// Helper to convert hex string to Color (if needed for ChapitreModel later)
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

// Placeholder to convert string to IconData (if needed for ChapitreModel later)
IconData _stringToIconDataChapitre(String? iconName, {IconData defaultIcon = Icons.class_outlined}) { // Corrigé ici
  if (iconName == null) return defaultIcon;
  // Add mapping if ChapitreModel gets an icon string
  return defaultIcon;
}

class ChapitreDetailPage extends StatefulWidget {
  final MatiereModel matiere; // This is our new MatiereModel
  final ChapitreModel chapitre; // This is our new ChapitreModel

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
            _buildChapitreHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildBreadcrumb(),
            const SizedBox(height: 16),
            const Text(
              'Leçons',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildLeconsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChapitreHeader() {
    // ChapitreModel (new) doesn't have color, icon, difficulte, progression directly
    final Color placeholderColor = Colors.deepPurple; // Placeholder
    final IconData placeholderIcon = Icons.library_books; // Placeholder

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [placeholderColor, placeholderColor.withOpacity(0.7)],
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
                  placeholderIcon,
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
                      widget.matiere.nom, // MatiereModel's nom
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Difficulte placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'N/A', // Placeholder for difficulte
                  style: TextStyle(
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
            widget.chapitre.description ?? 'Aucune description pour ce chapitre.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Progression placeholder
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
                  const Text(
                    '0%', // Placeholder for progression
                    style: TextStyle(
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
                  value: 0.0, // Placeholder for progression
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
    // widget.chapitre.lecons (V1 structure) and widget.chapitre.nombreLecons are not directly available
    // Using placeholders
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Leçons',
            '0', // Placeholder
            Icons.article_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Terminées',
            '0', // Placeholder
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Durée',
            'N/A', // Placeholder
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
            widget.matiere.nom, // From MatiereModel
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          Text(
            widget.chapitre.nom, // From ChapitreModel
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
    // The field `widget.chapitre.lecons` is from the V1 mock data structure for ChapitreModel.
    // Our new ChapitreModel (from Supabase) does not have a `lecons` field directly.
    // This list would need to be fetched separately (e.g., using leconProvider.fetchLeconsByChapter).
    // For now, to ensure compilation and avoid runtime errors with mismatched LeconModel types,
    // we'll use an empty list for `leconsTriees`.
    final List<LeconModel> leconsTriees = []; // Empty list as placeholder

    if (leconsTriees.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Aucune leçon disponible pour ce chapitre pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),),
          )
        );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leconsTriees.length,
      itemBuilder: (context, index) {
        final lecon = leconsTriees[index]; // This will be our new LeconModel
        // The logic for estPrecedenteComplete and estAccessible needs to be re-evaluated
        // as our new LeconModel doesn't have 'estComplete' directly.
        // Using true as placeholder for accessibility for now.
        final bool estAccessible = true; 
        return _buildLeconCard(lecon, index + 1, estAccessible);
      },
    );
  }

  // This card needs to be adapted to our new LeconModel
  Widget _buildLeconCard(LeconModel lecon, int numero, bool estAccessible) {
    // Our new LeconModel has: nom, description, type, dureeEstimee (int?), ordre, etc.
    // It does NOT have: estComplete, typeColor, typeIcon, titre (use nom), dureeEstimeeTexte.
    final Color placeholderLeconColor = Colors.orange; // Placeholder
    final IconData placeholderLeconIcon = Icons.play_circle_outline; // Placeholder
    final String dureeTexte = lecon.dureeEstimee != null ? '${lecon.dureeEstimee} min' : 'N/A';
    // 'estComplete' is not in our LeconModel. Using false as placeholder.
    final bool estCompletePlaceholder = false; 

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeconDetailPage(
                  matiere: widget.matiere, // Corrigé ici
                  chapitre: widget.chapitre, // Pass our ChapitreModel
                  lecon: lecon, // Pass our LeconModel
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: estCompletePlaceholder
                          ? Colors.green
                          : estAccessible
                          ? placeholderLeconColor.withOpacity(0.1)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: estCompletePlaceholder
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                        '$numero',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: estAccessible ? placeholderLeconColor : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              placeholderLeconIcon, // Placeholder
                              size: 18,
                              color: estAccessible ? placeholderLeconColor : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lecon.type.toUpperCase(), // From LeconModel
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: estAccessible ? placeholderLeconColor : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecon.nom, // From LeconModel (was titre)
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: estAccessible ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecon.description ?? 'Pas de description.', // From LeconModel
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
                              dureeTexte, // Calculated from lecon.dureeEstimee
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (estCompletePlaceholder) ...[
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
