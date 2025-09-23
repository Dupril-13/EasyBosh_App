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
  int _dureeSecondes = 0; // La durée sera initialisée à partir des epreuveDetails
  bool _estEnPause = false;

  @override
  void initState() {
    super.initState();
    // Convertir la durée (ex: "2h", "90min") en secondes et démarrer le timer
    _initialiserEtDemarrerTimer();
  }

  void _initialiserEtDemarrerTimer() {
    String dureeStr = widget.epreuveDetails['duree'] ?? '0h'; // Durée par défaut 0 si non fournie
    // Logique simple pour parser la durée. Peut être améliorée.
    if (dureeStr.contains('h')) {
      dureeStr = dureeStr.replaceAll('h', '');
      int heures = int.tryParse(dureeStr.split(' ')[0]) ?? 0;
      _dureeSecondes = heures * 3600;
    } else if (dureeStr.contains('min')) {
      dureeStr = dureeStr.replaceAll('min', '');
      int minutes = int.tryParse(dureeStr.split(' ')[0]) ?? 0;
      _dureeSecondes = minutes * 60;
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
            // TODO: Gérer la fin du temps (soumission automatique, etc.)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Temps écoulé !')),
            );
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

  void _arreterEpreuve() {
    _timer?.cancel();
    // TODO: Logique pour arrêter et peut-être soumettre l'épreuve
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Épreuve arrêtée.')),
    );
    if (context.canPop()) context.pop(); // Revenir à la page des détails
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
          // Prévenir le retour facile si l'épreuve est en cours
          onPressed: () {
            // Afficher une confirmation avant de quitter
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
                      _arreterEpreuve(); // Arrête l'épreuve et pop la page
                    },
                  ),
                ],
              ),
            );
          },
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
            // Placeholder pour le contenu de l'épreuve
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
            // Boutons de contrôle
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
                  onPressed: _arreterEpreuve,
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
