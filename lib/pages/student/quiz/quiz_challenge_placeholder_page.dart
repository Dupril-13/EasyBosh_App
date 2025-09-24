
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizChallengePlaceholderPage extends StatelessWidget {
  const QuizChallengePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quiz'); // Corrigé de /quiz_page à /quiz
            }
          },
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Quiz Challenge - Bientôt disponible !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Préparez-vous pour des défis intenses !',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
