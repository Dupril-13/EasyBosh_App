import 'package:flutter/material.dart';

class MatiereDetailPage extends StatelessWidget {
  final int matiereId;
  const MatiereDetailPage({super.key, required this.matiereId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matière $matiereId')),
      body: const Center(child: Text('Détail matière')),
    );
  }
}