import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';
import 'package:easybosh_v2/providers/auth_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';

class EpreuveDetailsPage extends ConsumerWidget {
  final Epreuve epreuve;

  const EpreuveDetailsPage({super.key, required this.epreuve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final progressionState = ref.watch(epreuveProgressionProvider);

    // Vérifier si l'épreuve est déjà commencée ou terminée
    final isStarted = epreuve.id != null && progressionState.containsKey(epreuve.id!);
    final isCompleted = isStarted && progressionState[epreuve.id!]!.termine;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Détails de l\'épreuve',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de l'épreuve
            Text(
              epreuve.nom,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Badge de statut
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Épreuve terminée',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else if (isStarted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle, size: 16, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      'En cours',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Card avec informations principales
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.subject_outlined,
                      'Matière',
                      epreuve.matiereDisplay,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.grade_outlined,
                      'Niveau',
                      epreuve.niveauScolaireDisplay,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.assignment_ind_outlined,
                      'Série(s)',
                      epreuve.seriesCodes.join(', '),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.timer_outlined,
                      'Durée',
                      '${epreuve.dureeMinutes} minutes',
                    ),
                    if (epreuve.typeEpreuve == EpreuveType.ancienSujet && epreuve.anneeExamen != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Année',
                        epreuve.anneeExamen.toString(),
                      ),
                    ],
                    if (epreuve.typeEpreuve == EpreuveType.ancienSujet && epreuve.sessionExamen != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.school_outlined,
                        'Session',
                        epreuve.sessionExamen!,
                      ),
                    ],
                    if (epreuve.typeEpreuve == EpreuveType.sujetCollege && epreuve.nomEtablissement != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.business_outlined,
                        'Établissement',
                        epreuve.nomEtablissement!,
                      ),
                    ],
                    if (epreuve.typeEpreuve == EpreuveType.sujetCollege && epreuve.villeEtablissement != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Ville',
                        epreuve.villeEtablissement!,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Description si disponible
            if (epreuve.description != null && epreuve.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    epreuve.description!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Boutons d'action
            if (isCompleted) ...[
              // Si l'épreuve est terminée, afficher le bouton de correction
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 22),
                label: const Text('Voir la Correction', style: TextStyle(fontSize: 16)),
                onPressed: epreuve.corrigePdfUrl != null
                    ? () => context.push('/epreuve_correction', extra: epreuve)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
              if (epreuve.corrigePdfUrl == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Corrigé non disponible pour cette épreuve',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Recommencer', style: TextStyle(fontSize: 16)),
                onPressed: () => _showRestartDialog(context, ref, currentUser),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange, width: 1.5),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (isStarted) ...[
              // Si l'épreuve est commencée, proposer de continuer
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text('Continuer l\'Épreuve', style: TextStyle(fontSize: 16)),
                onPressed: () => context.push('/epreuve_composition', extra: epreuve),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ] else ...[
              // Nouvelle épreuve
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text('Commencer l\'Épreuve', style: TextStyle(fontSize: 16)),
                onPressed: () => _startEpreuve(context, ref, currentUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Future<void> _startEpreuve(BuildContext context, WidgetRef ref, dynamic currentUser) async {
    if (currentUser == null || epreuve.id == null) return;

    try {
      // Enregistrer le début de l'épreuve
      await ref.read(epreuveProgressionProvider.notifier).startEpreuve(
        epreuve.id!,
        currentUser.uid,
      );

      if (context.mounted) {
        // Navigation vers la page de composition
        context.push('/epreuve_composition', extra: epreuve);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestartDialog(BuildContext context, WidgetRef ref, dynamic currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommencer l\'épreuve'),
        content: const Text(
          'Voulez-vous vraiment recommencer cette épreuve ? Votre progression actuelle sera perdue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startEpreuve(context, ref, currentUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }
}