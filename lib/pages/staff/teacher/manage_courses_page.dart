import 'package:flutter/material.dart';

class ManageCoursesPage extends StatelessWidget {
  const ManageCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
      ),
      body: const Center(
        child: Text('Page de Gestion des Cours à venir.'),
      ),
    );
  }
}
