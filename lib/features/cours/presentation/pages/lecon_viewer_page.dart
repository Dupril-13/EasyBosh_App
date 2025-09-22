import 'package:flutter/material.dart';

class LeconViewerPage extends StatelessWidget {
  final int leconId;
  const LeconViewerPage({super.key, required this.leconId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leçon $leconId')),
      body: const Center(child: Text('Lecteur de leçon')),
    );
  }
}