import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/pages/common/pdf_viewer_page.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';

class EpreuveCorrectionPage extends ConsumerWidget {
  final Epreuve epreuve;

  const EpreuveCorrectionPage({super.key, required this.epreuve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressionState = ref.watch(epreuveProgressionProvider);
    final progression = epreuve.id != null ? progressionState[epreuve.id!] : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Corrigé',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.blue),
            onPressed: () => context.go('/epreuves'),
            tooltip: 'Retour aux épreuves',
          ),
        ],
      ),
      body: Column(
        children: [
          // Carte d'informations sur la soumission
          if (progression != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Épreuve terminée',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (progression.tempsPasse != null)
                              Text(
                                'Temps passé: ${_formatDuration(progression.tempsPasse!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (progression.submittedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Soumis le ${_formatDate(progression.submittedAt!)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

          // Affichage du corrigé ou message si non disponible
          Expanded(
            child: epreuve.corrigePdfUrl != null && epreuve.corrigePdfUrl!.isNotEmpty
                ? PdfViewerPage(
              pdfUrl: epreuve.corrigePdfUrl!,
              lessonTitle: 'Corrigé - ${epreuve.nom}',
            )
                : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Corrigé non disponible',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Le corrigé de cette épreuve n\'a pas encore été publié.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/epreuves'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour aux épreuves'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min ${secs}s';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}