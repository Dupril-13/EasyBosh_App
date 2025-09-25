import 'package:flutter/material.dart';

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs d\'Activité'),
      ),
      body: const Center(
        child: Text('Page des Logs d\'Activité à venir.'),
      ),
    );
  }
}
