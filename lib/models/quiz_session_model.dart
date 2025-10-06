import 'package:equatable/equatable.dart';

class QuizSessionModel extends Equatable {
  final int id;
  final String userId;
  final int quizId;
  final int tentative;
  final double score;
  final double? noteSurBaremeQuiz;
  final int tempsPasse; // en secondes
  final bool termine;
  final bool? reussi;
  final Map<String, dynamic> reponsesUtilisateur; // JSONB
  final DateTime startedAt;
  final DateTime? completedAt;

  const QuizSessionModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.tentative,
    required this.score,
    this.noteSurBaremeQuiz,
    required this.tempsPasse,
    required this.termine,
    this.reussi,
    required this.reponsesUtilisateur,
    required this.startedAt,
    this.completedAt,
  });

  factory QuizSessionModel.fromMap(Map<String, dynamic> map) {
    return QuizSessionModel(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      quizId: map['quiz_id'] as int,
      tentative: map['tentative'] as int? ?? 1,
      score: (map['score'] as num).toDouble(),
      noteSurBaremeQuiz: (map['note_sur_bareme_quiz'] as num?)?.toDouble(),
      tempsPasse: map['temps_passe'] as int? ?? 0,
      termine: map['termine'] as bool? ?? false,
      reussi: map['reussi'] as bool?,
      reponsesUtilisateur: map['reponses_utilisateur'] != null
          ? Map<String, dynamic>.from(map['reponses_utilisateur'] as Map)
          : {},
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'tentative': tentative,
      'score': score,
      'note_sur_bareme_quiz': noteSurBaremeQuiz,
      'temps_passe': tempsPasse,
      'termine': termine,
      'reussi': reussi,
      'reponses_utilisateur': reponsesUtilisateur,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'user_id': userId,
      'quiz_id': quizId,
      'tentative': tentative,
      'score': score,
      'note_sur_bareme_quiz': noteSurBaremeQuiz,
      'temps_passe': tempsPasse,
      'termine': termine,
      'reussi': reussi,
      'reponses_utilisateur': reponsesUtilisateur,
    };
  }

  QuizSessionModel copyWith({
    int? id,
    String? userId,
    int? quizId,
    int? tentative,
    double? score,
    double? noteSurBaremeQuiz,
    int? tempsPasse,
    bool? termine,
    bool? reussi,
    Map<String, dynamic>? reponsesUtilisateur,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return QuizSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      tentative: tentative ?? this.tentative,
      score: score ?? this.score,
      noteSurBaremeQuiz: noteSurBaremeQuiz ?? this.noteSurBaremeQuiz,
      tempsPasse: tempsPasse ?? this.tempsPasse,
      termine: termine ?? this.termine,
      reussi: reussi ?? this.reussi,
      reponsesUtilisateur: reponsesUtilisateur ?? this.reponsesUtilisateur,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    quizId,
    tentative,
    score,
    noteSurBaremeQuiz,
    tempsPasse,
    termine,
    reussi,
    reponsesUtilisateur,
    startedAt,
    completedAt,
  ];
}