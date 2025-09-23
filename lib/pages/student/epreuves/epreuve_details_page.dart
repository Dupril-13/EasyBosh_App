import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EpreuveDetailsPage extends StatelessWidget {
  final Map<String, String> epreuveDetails;

  const EpreuveDetailsPage({super.key, required this.epreuveDetails});

  @override
  Widget build(BuildContext context) {
    final String titre = epreuveDetails['titre'] ?? 'Détails de l\'épreuve';
    final String matiere = epreuveDetails['matiere'] ?? 'N/A';
    final String annee = epreuveDetails['annee'] ?? 'N/A';
    final String serie = epreuveDetails['serie'] ?? 'N/A';
    final String duree = epreuveDetails['duree'] ?? '2h'; 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: Text(
          titre,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations sur l\'épreuve',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.book_outlined, 'Matière', matiere),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Année', annee),
                    _buildDetailRow(Icons.assignment_ind_outlined, 'Série', serie),
                    _buildDetailRow(Icons.timer_outlined, 'Durée indicative', duree),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_note, size: 24),
              label: const Text('Commencer l\'Épreuve', style: TextStyle(fontSize: 18)),
              onPressed: () {
                context.go('/epreuve_composition', extra: epreuveDetails);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 20),
              label: const Text('Voir la Correction', style: TextStyle(fontSize: 16)),
              onPressed: () {
                context.go('/epreuve_correction', extra: epreuveDetails);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
