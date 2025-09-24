import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Pour le Timer

class EpreuveCompositionPage extends StatefulWidget {
  final Map<String, String> epreuveDetails;

  const EpreuveCompositionPage({super.key, required this.epreuveDetails});

  @override
  State<EpreuveCompositionPage> createState() => _EpreuveCompositionPageState();
}

class _EpreuveCompositionPageState extends State<EpreuveCompositionPage> {
  Timer? _timer;
  int _dureeSecondes = 0;
  bool _estEnPause = false;

  @override
  void initState() {
    super.initState();
    _initialiserEtDemarrerTimer();
  }

  void _initialiserEtDemarrerTimer() {
    String dureeStr = widget.epreuveDetails['duree'] ?? '0h';
    _dureeSecondes = 0; // Réinitialiser avant parsing

    // Tenter de parser XhYmin, Xh, Ymin
    final RegExp heureMinRegex = RegExp(r'(?:(\d+)h)?(?:(\d+)min)?');
    final match = heureMinRegex.firstMatch(dureeStr);

    if (match != null) {
      final heuresStr = match.group(1);
      final minutesStr = match.group(2);

      if (heuresStr != null) {
        _dureeSecondes += (int.tryParse(heuresStr) ?? 0) * 3600;
      }
      if (minutesStr != null) {
        _dureeSecondes += (int.tryParse(minutesStr) ?? 0) * 60;
      }
    } else {
      // Fallback pour un format simple Xh ou Ymin si regex échoue (peu probable avec la regex actuelle)
      if (dureeStr.contains('h') && !dureeStr.contains('min')) {
        _dureeSecondes = (int.tryParse(dureeStr.replaceAll('h', '').trim()) ?? 0) * 3600;
      } else if (dureeStr.contains('min') && !dureeStr.contains('h')) {
        _dureeSecondes = (int.tryParse(dureeStr.replaceAll('min', '').trim()) ?? 0) * 60;
      }
    }

    if (_dureeSecondes <= 0 && dureeStr != '0h') { // Si parsing a échoué et ce n'est pas 0h, log ou mettre une durée par défaut
        print("Erreur de parsing de la durée: $dureeStr. Mise à 0 secondes.");
        _dureeSecondes = 0;
    }

    if (_dureeSecondes > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_estEnPause) {
          if (_dureeSecondes > 0) {
            setState(() {
              _dureeSecondes--;
            });
          } else {
            _timer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Temps écoulé !')),
            );
            // TODO: Gérer la fin du temps (soumission automatique, redirection?)
          }
        }
      });
    }
  }

  void _togglePauseResume() {
    setState(() {
      _estEnPause = !_estEnPause;
    });
  }

  // Sera modifié pour la nouvelle logique de confirmation
  void _arreterEpreuveEtVoirCorrection() {
    _timer?.cancel();
    // Naviguer vers la page de correction
    // Assurez-vous que epreuveDetails est bien disponible et correct
    context.go('/epreuve_correction', extra: widget.epreuveDetails);
  }

  void _arreterEpreuveEtQuitter() {
    _timer?.cancel();
    if (context.canPop()) {
      context.pop(); // Revenir à la page des détails (ou la précédente dans la pile)
    } else {
      // Fallback si on ne peut pas pop (ex: page ouverte directement)
      context.go('/epreuves'); 
    }
  }

  void _afficherConfirmationArreter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arrêter l\'épreuve ?'),
        content: const Text('Voulez-vous vraiment arrêter cette épreuve et voir la correction ?'),
        actions: [
          TextButton(
            child: const Text('Non'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Oui, voir correction', style: TextStyle(color: Colors.green)),
            onPressed: () {
              Navigator.of(ctx).pop(); // Ferme le dialogue
              _arreterEpreuveEtVoirCorrection();
            },
          ),
        ],
      ),
    );
  }

  void _afficherConfirmationQuitter() {
     showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quitter l\'épreuve ?'),
          content: const Text('Si vous quittez, votre progression pourrait ne pas être sauvegardée. Êtes-vous sûr ?'),
          actions: [
            TextButton(
              child: const Text('Rester'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Quitter', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(ctx).pop(); // Ferme le dialogue
                _arreterEpreuveEtQuitter(); // Arrête l'épreuve et pop la page
              },
            ),
          ],
        ),
      );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _tempsRestantFormatted {
    int heures = _dureeSecondes ~/ 3600;
    int minutes = (_dureeSecondes % 3600) ~/ 60;
    int secondes = _dureeSecondes % 60;
    return "${heures.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secondes.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final String titreEpreuve = widget.epreuveDetails['titre'] ?? 'Composition';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: _afficherConfirmationQuitter, // Utilise la modale de confirmation standard pour quitter
        ),
        title: Text(
          titreEpreuve,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18, overflow: TextOverflow.ellipsis),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _tempsRestantFormatted,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dureeSecondes < 600 ? Colors.red : Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Contenu de l\'épreuve (Questions, etc.) ici',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(_estEnPause ? Icons.play_arrow : Icons.pause),
                  label: Text(_estEnPause ? 'Reprendre' : 'Pause'),
                  onPressed: _togglePauseResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Arrêter'),
                  onPressed: _afficherConfirmationArreter, // Utilise la nouvelle modale pour arrêter et voir correction
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
