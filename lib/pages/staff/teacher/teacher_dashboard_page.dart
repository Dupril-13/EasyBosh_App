import 'package:flutter/material.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Enseignant'),
      ),
      body: const Center(
        child: Text('Contenu du Tableau de Bord Enseignant à venir.'),
      ),
    );
  }
}
