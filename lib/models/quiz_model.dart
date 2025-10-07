
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
  final int? tempsLimite; // en secondes
  final int nombreQuestions;
  final double notePassage;
  final int tentativesMax;
  final bool melangerQuestions;
  final bool melangerReponses;
  final bool feedbackImmediat;
  final bool afficherCorrectionFinale;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

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
    required this.tentativesMax,
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
      notePassage: (map['note_passage'] as num? ?? 10.0).toDouble(),
      tentativesMax: map['tentatives_max'] as int? ?? 3,
      melangerQuestions: map['melanger_questions'] as bool? ?? true,
      melangerReponses: map['melanger_reponses'] as bool? ?? true,
      feedbackImmediat: map['feedback_immediat'] as bool? ?? false,
      afficherCorrectionFinale: map['afficher_correction_finale'] as bool? ?? true,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      createdBy: map['created_by'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, nom, chapitreId, matiereId];
}
