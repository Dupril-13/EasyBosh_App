import 'package:flutter/material.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Enseignant'),
      ),
      body: const Center(
        child: Text('Page de Profil Enseignant à venir.'),
      ),
    );
  }
}
