import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';
import 'package:easybosh_v2/pages/common/pdf_viewer_page.dart';

class EpreuveCompositionPage extends ConsumerStatefulWidget {
  final Epreuve epreuve;

  const EpreuveCompositionPage({super.key, required this.epreuve});

  @override
  ConsumerState<EpreuveCompositionPage> createState() => _EpreuveCompositionPageState();
}

class _EpreuveCompositionPageState extends ConsumerState<EpreuveCompositionPage> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.epreuve.sujetPdfUrl == null || widget.epreuve.sujetPdfUrl!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Épreuve'),
        ),
        body: const Center(
          child: Text('Le sujet de cette épreuve n\'est pas disponible.'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Confirmer avant de quitter
        final shouldPop = await _showExitConfirmDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
            onPressed: () async {
              final shouldPop = await _showExitConfirmDialog();
              if (shouldPop == true && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.epreuve.nom,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Composition en cours',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            // Timer affiché dans l'AppBar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTimerColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Barre de progression (optionnelle)
            if (widget.epreuve.dureeMinutes > 0)
              LinearProgressIndicator(
                value: _elapsedSeconds / (widget.epreuve.dureeMinutes * 60),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
              ),

            // Affichage du PDF du sujet
            Expanded(
              child: PdfViewerPage(
                pdfUrl: widget.epreuve.sujetPdfUrl!,
                lessonTitle: 'Sujet - ${widget.epreuve.nom}',
              ),
            ),

            // Bouton de soumission fixe en bas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _showSubmitDialog,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    _isSubmitting ? 'Soumission...' : 'Terminer et Soumettre',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimerColor() {
    if (widget.epreuve.dureeMinutes == 0) return Colors.blue;

    final percentage = _elapsedSeconds / (widget.epreuve.dureeMinutes * 60);
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    return Colors.blue;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la composition'),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter ? Votre progression sera sauvegardée et vous pourrez reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rester'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la soumission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir soumettre votre copie ?'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Temps écoulé: ${_formatDuration(_elapsedSeconds)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (widget.epreuve.dureeMinutes > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Durée recommandée: ${widget.epreuve.dureeMinutes} min',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitEpreuve();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEpreuve() async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || widget.epreuve.id == null) {
        throw Exception('Utilisateur non connecté ou épreuve invalide');
      }

      await ref.read(epreuveProgressionProvider.notifier).submitEpreuve(
        widget.epreuve.id!,
        currentUser.uid,
        _elapsedSeconds,
      );

      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épreuve soumise avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Attendre un peu pour que l'utilisateur voit le message
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // Naviguer vers la page de correction si disponible, sinon retour
          if (widget.epreuve.corrigePdfUrl != null) {
            context.go('/epreuve_correction', extra: widget.epreuve);
          } else {
            context.go('/epreuves');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}