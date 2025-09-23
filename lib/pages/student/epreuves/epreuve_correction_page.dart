import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EpreuveCorrectionPage extends StatelessWidget {
  final Map<String, String> epreuveDetails;

  const EpreuveCorrectionPage({super.key, required this.epreuveDetails});

  @override
  Widget build(BuildContext context) {
    final String titreEpreuve = epreuveDetails['titre'] ?? 'Correction';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Correction: ${titreEpreuve.isNotEmpty ? titreEpreuve : "Épreuve"}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18, // Ajusté pour potentiellement des titres longs
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder pour le contenu de la correction
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Contenu de la Correction',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'La correction détaillée pour cette épreuve sera affichée ici.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Vous pourriez ajouter d'autres sections ici si nécessaire,
            // par exemple des statistiques de réussite, des commentaires, etc.
          ],
        ),
      ),
    );
  }
}
