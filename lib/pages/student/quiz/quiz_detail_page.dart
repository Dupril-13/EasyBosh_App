import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/quiz_model.dart';
import '../../../providers/current_quiz_provider.dart';
import '../../../providers/quiz_session_provider.dart';

class QuizDetailPage extends ConsumerStatefulWidget {
  final QuizModel quiz;

  const QuizDetailPage({super.key, required this.quiz});

  @override
  ConsumerState<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends ConsumerState<QuizDetailPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentQuizProvider.notifier).loadQuiz(widget.quiz.id);
    });
  }

  Future<void> _startQuiz() async {
    setState(() => _isLoading = true);

    try {
      final quizState = ref.read(currentQuizProvider);
      if (quizState.quiz == null || quizState.questions.isEmpty) {
        await ref.read(currentQuizProvider.notifier).loadQuiz(widget.quiz.id);
      }

      await ref.read(quizSessionProvider.notifier).startSession(widget.quiz.id);

      final sessionState = ref.read(quizSessionProvider);
      if (sessionState.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sessionState.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        context.push('/quiz_session', extra: widget.quiz);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(currentQuizProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Détails du Quiz',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: quizState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildInfoSection(),
            _buildDescriptionSection(),
            _buildInstructionsSection(),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.quiz.nom,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.quiz.description != null &&
              widget.quiz.description!.isNotEmpty)
            Text(
              widget.quiz.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final quizState = ref.watch(currentQuizProvider);
    final nombreQuestions = quizState.questions.isNotEmpty
        ? quizState.questions.length
        : widget.quiz.nombreQuestions;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.question_answer,
            'Questions',
            '$nombreQuestions questions',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.timer_outlined,
            'Durée',
            widget.quiz.tempsLimite != null
                ? '${widget.quiz.tempsLimite} minutes'
                : 'Pas de limite de temps',
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.grade,
            'Score maximum',
            '${_calculateMaxScore()} points',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.visibility,
            'Résultats',
            'Visibles après soumission',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    if (widget.quiz.description == null || widget.quiz.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.quiz.description!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstruction(
            '1. Lisez attentivement chaque question',
          ),
          _buildInstruction(
            '2. Sélectionnez la ou les réponse(s) correcte(s)',
          ),
          if (widget.quiz.tempsLimite != null)
            _buildInstruction(
              '3. Gérez votre temps (${widget.quiz.tempsLimite} minutes)',
            ),
          _buildInstruction(
            '${widget.quiz.tempsLimite != null ? '4' : '3'}. Votre progression est sauvegardée automatiquement',
          ),
          if (widget.quiz.feedbackImmediat)
            _buildInstruction(
              '${widget.quiz.tempsLimite != null ? '5' : '4'}. Feedback immédiat après chaque réponse',
            ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final sessionState = ref.watch(quizSessionProvider);
    final hasOngoingSession = sessionState.currentSession != null &&
        !sessionState.currentSession!.termine;

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _startQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasOngoingSession
                    ? Icons.play_circle_outline
                    : Icons.start,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasOngoingSession
                    ? 'Reprendre le Quiz'
                    : 'Commencer le Quiz',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateMaxScore() {
    final quizState = ref.read(currentQuizProvider);
    if (quizState.questions.isNotEmpty) {
      return quizState.questions.fold(0.0, (sum, q) => sum + q.points);
    }
    return widget.quiz.nombreQuestions.toDouble();
  }
}