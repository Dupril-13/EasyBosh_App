import 'package:flutter/material.dart';

class ManageExamsPage extends StatelessWidget {
  const ManageExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Épreuves'),
      ),
      body: const Center(
        child: Text('Page de Gestion des Épreuves à venir.'),
      ),
    );
  }
}
