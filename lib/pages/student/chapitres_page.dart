import 'package:flutter/material.dart';

class ChapitresPage extends StatelessWidget {
  final int matiereId;
  final String typeContenu;
  const ChapitresPage({super.key, required this.matiereId, required this.typeContenu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chapitres $typeContenu')),
      body: const Center(child: Text('Liste chapitres')),
    );
  }
}