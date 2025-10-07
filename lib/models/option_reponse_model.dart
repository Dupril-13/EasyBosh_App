
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

  @override
  List<Object?> get props => [id, questionId, texte, estCorrecte];
}
