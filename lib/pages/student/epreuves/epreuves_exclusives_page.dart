import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EpreuvesExclusivesPage extends StatelessWidget {
  const EpreuvesExclusivesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/epreuves');
            }
          },
        ),
        title: const Text(
          'Épreuves Exclusives',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border_outlined, size: 80, color: Colors.purple[300]),
              const SizedBox(height: 24),
              const Text(
                'Épreuves Exclusives',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Contenu bientôt disponible',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Des épreuves créées exclusivement par la plateforme seront disponibles ici.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}