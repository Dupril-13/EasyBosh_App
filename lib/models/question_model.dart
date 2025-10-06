import 'package:equatable/equatable.dart';
import 'option_reponse_model.dart';

enum QuestionType {
  qcmUnique,
  qcmMultiple,
  vraiFaux,
  texteLibre,
  numerique,
  association;

  static QuestionType fromString(String type) {
    switch (type) {
      case 'qcm_unique':
        return QuestionType.qcmUnique;
      case 'qcm_multiple':
        return QuestionType.qcmMultiple;
      case 'vrai_faux':
        return QuestionType.vraiFaux;
      case 'texte_libre':
        return QuestionType.texteLibre;
      case 'numerique':
        return QuestionType.numerique;
      case 'association':
        return QuestionType.association;
      default:
        throw Exception('Type de question inconnu: $type');
    }
  }

  String toDbString() {
    switch (this) {
      case QuestionType.qcmUnique:
        return 'qcm_unique';
      case QuestionType.qcmMultiple:
        return 'qcm_multiple';
      case QuestionType.vraiFaux:
        return 'vrai_faux';
      case QuestionType.texteLibre:
        return 'texte_libre';
      case QuestionType.numerique:
        return 'numerique';
      case QuestionType.association:
        return 'association';
    }
  }
}

class QuestionModel extends Equatable {
  final int id;
  final int quizId;
  final String texte;
  final QuestionType type;
  final int ordre;
  final double points;
  final String? explication;
  final String? imageUrl;
  final List<OptionReponseModel> options;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    required this.createdAt,
    this.updatedAt,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    List<OptionReponseModel> parsedOptions = [];
    if (map['options'] != null && map['options'] is List) {
      parsedOptions = (map['options'] as List)
          .map((opt) => OptionReponseModel.fromMap(opt as Map<String, dynamic>))
          .toList();
    }

    return QuestionModel(
      id: map['id'] as int,
      quizId: map['quiz_id'] as int,
      texte: map['texte'] as String,
      type: QuestionType.fromString(map['type'] as String),
      ordre: map['ordre'] as int? ?? 0,
      points: (map['points'] as num?)?.toDouble() ?? 1.0,
      explication: map['explication'] as String?,
      imageUrl: map['image_url'] as String?,
      options: parsedOptions,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'texte': texte,
      'type': type.toDbString(),
      'ordre': ordre,
      'points': points,
      'explication': explication,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'quiz_id': quizId,
      'texte': texte,
      'type': type.toDbString(),
      'ordre': ordre,
      'points': points,
      'explication': explication,
      'image_url': imageUrl,
    };
  }

  QuestionModel copyWith({
    int? id,
    int? quizId,
    String? texte,
    QuestionType? type,
    int? ordre,
    double? points,
    String? explication,
    String? imageUrl,
    List<OptionReponseModel>? options,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      texte: texte ?? this.texte,
      type: type ?? this.type,
      ordre: ordre ?? this.ordre,
      points: points ?? this.points,
      explication: explication ?? this.explication,
      imageUrl: imageUrl ?? this.imageUrl,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, quizId, texte, type, ordre, points, explication,
    imageUrl, options, createdAt, updatedAt,
  ];
}