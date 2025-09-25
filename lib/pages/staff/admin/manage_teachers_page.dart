import 'package:flutter/material.dart';

class ManageTeachersPage extends StatelessWidget {
  const ManageTeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Enseignants'),
      ),
      body: const Center(
        child: Text('Page de Gestion des Enseignants à venir.'),
      ),
    );
  }
}
