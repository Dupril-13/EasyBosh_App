import 'package:flutter/material.dart';

class LeconsPage extends StatelessWidget {
  final int chapitreId;
  const LeconsPage({super.key, required this.chapitreId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leçons du chapitre $chapitreId')),
      body: const Center(child: Text('Liste leçons')),
    );
  }
}