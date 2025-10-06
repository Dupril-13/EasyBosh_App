import 'package:equatable/equatable.dart';

class QuizModel extends Equatable {
  final int id;
  final int? chapitreId;
  final int? matiereId;
  final String? niveauCode;
  final String? serieCode;
  final String nom;
  final String? description;
  final String? instructions;
  final int? tempsLimite; // en minutes
  final int nombreQuestions;
  final double notePassage;
  final bool melangerQuestions;
  final bool melangerReponses;
  final bool feedbackImmediat;
  final bool afficherCorrectionFinale;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // UUID enseignant

  const QuizModel({
    required this.id,
    this.chapitreId,
    this.matiereId,
    this.niveauCode,
    this.serieCode,
    required this.nom,
    this.description,
    this.instructions,
    this.tempsLimite,
    required this.nombreQuestions,
    required this.notePassage,
    required this.melangerQuestions,
    required this.melangerReponses,
    required this.feedbackImmediat,
    required this.afficherCorrectionFinale,
    required this.actif,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] as int,
      chapitreId: map['chapitre_id'] as int?,
      matiereId: map['matiere_id'] as int?,
      niveauCode: map['niveau_code'] as String?,
      serieCode: map['serie_code'] as String?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      instructions: map['instructions'] as String?,
      tempsLimite: map['temps_limite'] as int?,
      nombreQuestions: map['nombre_questions'] as int? ?? 0,
      notePassage: (map['note_passage'] as num?)?.toDouble() ?? 10.0,
      melangerQuestions: map['melanger_questions'] as bool? ?? true,
      melangerReponses: map['melanger_reponses'] as bool? ?? true,
      feedbackImmediat: map['feedback_immediat'] as bool? ?? false,
      afficherCorrectionFinale: map['afficher_correction_finale'] as bool? ?? true,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapitre_id': chapitreId,
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'nom': nom,
      'description': description,
      'instructions': instructions,
      'temps_limite': tempsLimite,
      'nombre_questions': nombreQuestions,
      'note_passage': notePassage,
      'melanger_questions': melangerQuestions,
      'melanger_reponses': melangerReponses,
      'feedback_immediat': feedbackImmediat,
      'afficher_correction_finale': afficherCorrectionFinale,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'chapitre_id': chapitreId,
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'nom': nom,
      'description': description,
      'instructions': instructions,
      'temps_limite': tempsLimite,
      'nombre_questions': nombreQuestions,
      'note_passage': notePassage,
      'melanger_questions': melangerQuestions,
      'melanger_reponses': melangerReponses,
      'feedback_immediat': feedbackImmediat,
      'afficher_correction_finale': afficherCorrectionFinale,
      'actif': actif,
      'created_by': createdBy,
    };
  }

  QuizModel copyWith({
    int? id,
    int? chapitreId,
    int? matiereId,
    String? niveauCode,
    String? serieCode,
    String? nom,
    String? description,
    String? instructions,
    int? tempsLimite,
    int? nombreQuestions,
    double? notePassage,
    bool? melangerQuestions,
    bool? melangerReponses,
    bool? feedbackImmediat,
    bool? afficherCorrectionFinale,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return QuizModel(
      id: id ?? this.id,
      chapitreId: chapitreId ?? this.chapitreId,
      matiereId: matiereId ?? this.matiereId,
      niveauCode: niveauCode ?? this.niveauCode,
      serieCode: serieCode ?? this.serieCode,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      tempsLimite: tempsLimite ?? this.tempsLimite,
      nombreQuestions: nombreQuestions ?? this.nombreQuestions,
      notePassage: notePassage ?? this.notePassage,
      melangerQuestions: melangerQuestions ?? this.melangerQuestions,
      melangerReponses: melangerReponses ?? this.melangerReponses,
      feedbackImmediat: feedbackImmediat ?? this.feedbackImmediat,
      afficherCorrectionFinale: afficherCorrectionFinale ?? this.afficherCorrectionFinale,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
    id, chapitreId, matiereId, niveauCode, serieCode, nom, description,
    instructions, tempsLimite, nombreQuestions, notePassage,
    melangerQuestions, melangerReponses, feedbackImmediat,
    afficherCorrectionFinale, actif, createdAt, updatedAt, createdBy,
  ];
}