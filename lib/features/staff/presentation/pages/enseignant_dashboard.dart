import 'package:flutter/material.dart';

class EnseignantDashboard extends StatelessWidget {
  const EnseignantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Dashboard Enseignant', style: TextStyle(fontSize: 24)),
            Text('(En cours de développement)'),
          ],
        ),
      ),
    );
  }
}