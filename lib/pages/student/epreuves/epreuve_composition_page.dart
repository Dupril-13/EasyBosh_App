import 'dart:async';
import 'package:flutter/material.dart';
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
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _hasAutoSubmitted = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.epreuve.dureeMinutes * 60;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else if (_remainingSeconds == 0) {
        _timer?.cancel();
        if (!_hasAutoSubmitted && mounted) {
          _hasAutoSubmitted = true;
          _autoSubmitEpreuve();
        }
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
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
        appBar: AppBar(title: const Text('Épreuve')),
        body: const Center(
          child: Text('Le sujet de cette épreuve n\'est pas disponible.'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmDialog();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
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
              const Text(
                'Composition en cours',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
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
                  Icon(_isPaused ? Icons.pause : Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_remainingSeconds),
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
            if (widget.epreuve.dureeMinutes > 0)
              LinearProgressIndicator(
                value: 1 - (_remainingSeconds / (widget.epreuve.dureeMinutes * 60)),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                minHeight: 3,
              ),

            Expanded(
              child: PdfViewerPage(
                pdfUrl: widget.epreuve.sujetPdfUrl!,
                lessonTitle: 'Sujet - ${widget.epreuve.nom}',
                hideAppBar: true, // Nouveau paramètre pour cacher l'AppBar du PDF
              ),
            ),

            // Boutons Pause/Play + Terminer
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
                child: Row(
                  children: [
                    // Bouton Pause/Play
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                        label: Text(
                          _isPaused ? 'Reprendre' : 'Pause',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange, width: 1.5),
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bouton Terminer
                    Expanded(
                      flex: 3,
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
                          _isSubmitting ? 'Soumission...' : 'Terminer',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
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

    final percentage = _remainingSeconds / (widget.epreuve.dureeMinutes * 60);
    if (percentage <= 0.1) return Colors.red;
    if (percentage <= 0.25) return Colors.orange;
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
    final elapsedSeconds = (widget.epreuve.dureeMinutes * 60) - _remainingSeconds;

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
                  'Temps écoulé: ${_formatDuration(elapsedSeconds)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Temps restant: ${_formatDuration(_remainingSeconds)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
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

  Future<void> _autoSubmitEpreuve() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Temps écoulé ! Soumission automatique...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      await _submitEpreuve();
    }
  }

  Future<void> _submitEpreuve() async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || widget.epreuve.id == null) {
        throw Exception('Utilisateur non connecté ou épreuve invalide');
      }

      final elapsedSeconds = (widget.epreuve.dureeMinutes * 60) - _remainingSeconds;

      await ref.read(epreuveProgressionProvider.notifier).submitEpreuve(
        widget.epreuve.id!,
        currentUser.uid,
        elapsedSeconds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épreuve soumise avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
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