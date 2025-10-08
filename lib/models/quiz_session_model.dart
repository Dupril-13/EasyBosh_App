
// Represents the data fetched for a recent quiz session
class QuizSessionModel {
  final int id;
  final int quizId;
  final double score;
  final double noteSurBaremeQuiz;
  final DateTime completedAt;
  final String quizTitle;
  final String matiereNom;

  QuizSessionModel({
    required this.id,
    required this.quizId,
    required this.score,
    required this.noteSurBaremeQuiz,
    required this.completedAt,
    required this.quizTitle,
    required this.matiereNom,
  });

  factory QuizSessionModel.fromMap(Map<String, dynamic> map) {
    final quizData = map['quiz'] as Map<String, dynamic>? ?? {};
    final matiereData = quizData['matiere'] as Map<String, dynamic>? ?? {};

    return QuizSessionModel(
      id: map['id'] as int,
      quizId: map['quiz_id'] as int,
      score: (map['score'] as num).toDouble(),
      noteSurBaremeQuiz: (map['note_sur_bareme_quiz'] as num).toDouble(),
      completedAt: DateTime.parse(map['completed_at'] as String),
      quizTitle: quizData['nom'] as String? ?? 'Titre du quiz indisponible',
      matiereNom: matiereData['nom'] as String? ?? 'Matière indisponible',
    );
  }
}
