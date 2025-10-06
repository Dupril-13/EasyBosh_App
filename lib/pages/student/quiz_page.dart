// ================================================
// lib/pages/student/quiz_page.dart
// Hub principal des quiz avec placeholders
// ================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quiz',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec illustration
            _buildHeader(),
            const SizedBox(height: 24),

            // Section des types de quiz
            const Text(
              'Types de Quiz',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Quiz par Matière (ACTIF)
            _buildQuizTypeCard(
              title: 'Quiz par Matière',
              description: 'Testez vos connaissances par matière et par chapitre',
              icon: Icons.school,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isActive: true,
              onTap: () {
                context.push('/quiz_matiere_selection');
              },
            ),
            const SizedBox(height: 12),

            // Quiz Express (DÉSACTIVÉ)
            _buildQuizTypeCard(
              title: 'Quiz Express',
              description: 'Questions rapides pour une révision éclair',
              icon: Icons.flash_on,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isActive: false,
              onTap: () {
                _showComingSoonDialog(context, 'Quiz Express');
              },
            ),
            const SizedBox(height: 12),

            // Quiz Challenge (DÉSACTIVÉ)
            _buildQuizTypeCard(
              title: 'Quiz Challenge',
              description: 'Défiez d\'autres élèves et montez dans le classement',
              icon: Icons.emoji_events,
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isActive: false,
              onTap: () {
                _showComingSoonDialog(context, 'Quiz Challenge');
              },
            ),
            const SizedBox(height: 12),

            // Bilan de Niveau (DÉSACTIVÉ)
            _buildQuizTypeCard(
              title: 'Bilan de Niveau',
              description: 'Évaluez votre niveau global dans toutes les matières',
              icon: Icons.assessment,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade400,
                  Colors.cyan.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isActive: false,
              onTap: () {
                _showComingSoonDialog(context, 'Bilan de Niveau');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Évaluez vos connaissances et progressez',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.quiz,
            size: 80,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icône avec gradient
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isActive ? gradient : null,
                  color: isActive ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bientôt',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Icône de navigation
              Icon(
                isActive ? Icons.arrow_forward_ios : Icons.lock_outline,
                color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text('Bientôt disponible'),
            ],
          ),
          content: Text(
            '$feature sera bientôt disponible. Nous travaillons dur pour vous offrir cette fonctionnalité !',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Compris',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}