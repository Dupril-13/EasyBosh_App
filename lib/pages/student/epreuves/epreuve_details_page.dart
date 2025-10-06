import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';

class EpreuveDetailsPage extends ConsumerWidget {
  final Epreuve epreuve;

  const EpreuveDetailsPage({super.key, required this.epreuve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final progressionState = ref.watch(epreuveProgressionProvider);

    final isStarted = epreuve.id != null && progressionState.containsKey(epreuve.id!);
    final isCompleted = isStarted && progressionState[epreuve.id!]!.termine;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Détails de l\'épreuve',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    epreuve.nom,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  if (isCompleted || isStarted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.play_circle,
                            size: 16,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleted ? 'Épreuve terminée' : 'En cours',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.subject_outlined, 'Matière', epreuve.matiereDisplay),
                  _buildDivider(),
                  _buildDetailRow(Icons.grade_outlined, 'Niveau', epreuve.niveauScolaireDisplay),
                  _buildDivider(),
                  _buildDetailRow(Icons.assignment_ind_outlined, 'Série(s)', epreuve.seriesCodes.join(', ')),
                  _buildDivider(),
                  _buildDetailRow(Icons.timer_outlined, 'Durée', '${epreuve.dureeMinutes} minutes'),

                  if (epreuve.typeEpreuve == EpreuveType.ancienSujet && epreuve.anneeExamen != null) ...[
                    _buildDivider(),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Année', epreuve.anneeExamen.toString()),
                  ],

                  if (epreuve.typeEpreuve == EpreuveType.ancienSujet && epreuve.sessionExamen != null) ...[
                    _buildDivider(),
                    _buildDetailRow(Icons.school_outlined, 'Examen', epreuve.sessionExamen!),
                  ],

                  if (epreuve.typeEpreuve == EpreuveType.sujetCollege && epreuve.nomEtablissement != null) ...[
                    _buildDivider(),
                    _buildDetailRow(Icons.business_outlined, 'Établissement', epreuve.nomEtablissement!),
                  ],

                  if (epreuve.typeEpreuve == EpreuveType.sujetCollege && epreuve.villeEtablissement != null) ...[
                    _buildDivider(),
                    _buildDetailRow(Icons.location_on_outlined, 'Ville', epreuve.villeEtablissement!),
                  ],
                ],
              ),
            ),

            if (epreuve.description != null && epreuve.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      epreuve.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (isCompleted) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Recommencer l\'Épreuve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: () => _showRestartDialog(context, ref, currentUser),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 22),
                      label: const Text('Voir la Correction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: epreuve.corrigePdfUrl != null
                          ? () => context.push('/epreuve_correction', extra: epreuve)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(
                          color: epreuve.corrigePdfUrl != null ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledForegroundColor: Colors.grey[400],
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
                  ] else if (isStarted) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text('Continuer l\'Épreuve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: () => context.push('/epreuve_composition', extra: epreuve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 22),
                      label: const Text('Voir la Correction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: epreuve.corrigePdfUrl != null
                          ? () => context.push('/epreuve_correction', extra: epreuve)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(
                          color: epreuve.corrigePdfUrl != null ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledForegroundColor: Colors.grey[400],
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
                  ] else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text('Commencer l\'Épreuve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: () => _startEpreuve(context, ref, currentUser),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 22),
                      label: const Text('Voir la Correction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: epreuve.corrigePdfUrl != null
                          ? () => context.push('/epreuve_correction', extra: epreuve)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(
                          color: epreuve.corrigePdfUrl != null ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledForegroundColor: Colors.grey[400],
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
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }

  Future<void> _startEpreuve(BuildContext context, WidgetRef ref, dynamic currentUser) async {
    if (currentUser == null || epreuve.id == null) return;

    try {
      await ref.read(epreuveProgressionProvider.notifier).startEpreuve(
        epreuve.id!,
        currentUser.uid,
      );

      if (context.mounted) {
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recommencer l\'épreuve'),
        content: const Text(
          'Voulez-vous vraiment recommencer cette épreuve ? Votre progression actuelle sera perdue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (epreuve.id != null && currentUser != null) {
                try {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  await ref.read(epreuveProgressionProvider.notifier).startEpreuve(
                    epreuve.id!,
                    currentUser.uid,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  if (context.mounted) {
                    context.push('/epreuve_composition', extra: epreuve);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }
}