
import 'package:equatable/equatable.dart';
import 'package:easybosh_v2/models/option_reponse_model.dart';

class QuestionModel extends Equatable {
  final int id;
  final int quizId;
  final String texte;
  final String type; // 'qcm_unique', 'qcm_multiple', 'vrai_faux', etc.
  final int ordre;
  final double points;
  final String? explication;
  final String? imageUrl;
  final List<OptionReponseModel> options;

  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.texte,
    required this.type,
    required this.ordre,
    required this.points,
    this.explication,
    this.imageUrl,
    this.options = const [],
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, List<OptionReponseModel> options) {
    return QuestionModel(
      id: map['id'] as int,
      quizId: map['quiz_id'] as int,
      texte: map['texte'] as String,
      type: map['type'] as String,
      ordre: map['ordre'] as int? ?? 0,
      points: (map['points'] as num? ?? 1.0).toDouble(),
      explication: map['explication'] as String?,
      imageUrl: map['image_url'] as String?,
      options: options,
    );
  }

  @override
  List<Object?> get props => [id, quizId, texte, type, options];
}
