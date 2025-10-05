import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/pages/common/pdf_viewer_page.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';

class EpreuveCorrectionPage extends ConsumerStatefulWidget {
  final Epreuve epreuve;

  const EpreuveCorrectionPage({super.key, required this.epreuve});

  @override
  ConsumerState<EpreuveCorrectionPage> createState() => _EpreuveCorrectionPageState();
}

class _EpreuveCorrectionPageState extends ConsumerState<EpreuveCorrectionPage> {
  @override
  void initState() {
    super.initState();

    // Afficher le snackbar après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCompletionSnackbar();
    });
  }

  void _showCompletionSnackbar() {
    final progressionState = ref.read(epreuveProgressionProvider);
    final progression = widget.epreuve.id != null ? progressionState[widget.epreuve.id!] : null;

    if (progression != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Épreuve terminée',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (progression.tempsPasse != null)
                      Text(
                        'Temps: ${_formatDuration(progression.tempsPasse!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () {
            // Retourner vers la page d'où vient l'épreuve
            if (widget.epreuve.typeEpreuve == EpreuveType.ancienSujet) {
              context.go('/anciens_sujets');
            } else if (widget.epreuve.typeEpreuve == EpreuveType.sujetCollege) {
              context.go('/colleges_connus');
            } else {
              context.go('/epreuves');
            }
          },
        ),
        title: const Text(
          'Corrigé',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.blue, size: 22),
            onPressed: () => context.go('/epreuves'),
            tooltip: 'Retour aux épreuves',
          ),
        ],
      ),
      body: widget.epreuve.corrigePdfUrl != null && widget.epreuve.corrigePdfUrl!.isNotEmpty
          ? PdfViewerPage(
        pdfUrl: widget.epreuve.corrigePdfUrl!,
        lessonTitle: 'Corrigé - ${widget.epreuve.nom}',
        hideAppBar: true,
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
}