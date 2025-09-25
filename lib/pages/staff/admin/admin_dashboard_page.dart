import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
      ),
      body: const Center(
        child: Text('Contenu du Tableau de Bord Admin à venir.'),
      ),
    );
  }
}
