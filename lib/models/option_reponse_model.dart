import 'package:equatable/equatable.dart';

class OptionReponseModel extends Equatable {
  final int id;
  final int questionId;
  final String texte;
  final bool estCorrecte;
  final int ordre;
  final String? feedbackSpecifique;

  const OptionReponseModel({
    required this.id,
    required this.questionId,
    required this.texte,
    required this.estCorrecte,
    required this.ordre,
    this.feedbackSpecifique,
  });

  factory OptionReponseModel.fromMap(Map<String, dynamic> map) {
    return OptionReponseModel(
      id: map['id'] as int,
      questionId: map['question_id'] as int,
      texte: map['texte'] as String,
      estCorrecte: map['est_correcte'] as bool? ?? false,
      ordre: map['ordre'] as int? ?? 0,
      feedbackSpecifique: map['feedback_specifique'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'texte': texte,
      'est_correcte': estCorrecte,
      'ordre': ordre,
      'feedback_specifique': feedbackSpecifique,
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'question_id': questionId,
      'texte': texte,
      'est_correcte': estCorrecte,
      'ordre': ordre,
      'feedback_specifique': feedbackSpecifique,
    };
  }

  OptionReponseModel copyWith({
    int? id,
    int? questionId,
    String? texte,
    bool? estCorrecte,
    int? ordre,
    String? feedbackSpecifique,
  }) {
    return OptionReponseModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      texte: texte ?? this.texte,
      estCorrecte: estCorrecte ?? this.estCorrecte,
      ordre: ordre ?? this.ordre,
      feedbackSpecifique: feedbackSpecifique ?? this.feedbackSpecifique,
    );
  }

  @override
  List<Object?> get props => [
    id, questionId, texte, estCorrecte, ordre, feedbackSpecifique,
  ];
}