import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizChallengeListPage extends StatelessWidget {
  const QuizChallengeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Challenge', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1.0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
          onPressed: () {
            context.go('/quiz'); 
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined, size: 80, color: Colors.purple.shade300),
              const SizedBox(height: 24),
              Text(
                'Quiz Challenge - Bientôt disponible !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Préparez-vous à relever des défis chronométrés passionnants.\nCette section est en cours de finalisation.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                textAlign: TextAlign.center,
              ),
              // Vous pouvez ajouter un bouton si vous voulez, par exemple, pour notifier l'utilisateur
              // const SizedBox(height: 24),
              // ElevatedButton(onPressed: () {}, child: const Text('Me prévenir'))
            ],
          ),
        ),
      ),
    );
  }
}
