class ChapitreModel {
  final int id;
  final int? matiereId; // FK vers matieres.id
  final String? niveauCode; // FK vers niveaux.code
  final String? serieCode;  // FK vers series.code
  final String nom;
  final String? description;
  final int ordre;
  final int? dureeEstimee; // en minutes ?
  final List<String>? objectifs; // Vient de ARRAY dans la BD
  final List<String>? prerequis; // Vient de ARRAY dans la BD
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // UUID de l'utilisateur profile

  ChapitreModel({
    required this.id,
    this.matiereId,
    this.niveauCode,
    this.serieCode,
    required this.nom,
    this.description,
    required this.ordre,
    this.dureeEstimee,
    this.objectifs,
    this.prerequis,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory ChapitreModel.fromMap(Map<String, dynamic> map) {
    return ChapitreModel(
      id: map['id'] as int,
      matiereId: map['matiere_id'] as int?,
      niveauCode: map['niveau_code'] as String?,
      serieCode: map['serie_code'] as String?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      ordre: map['ordre'] as int? ?? 0,
      dureeEstimee: map['duree_estimee'] as int?,
      objectifs: (map['objectifs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      prerequis: (map['prerequis'] as List<dynamic>?)?.map((e) => e as String).toList(),
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // Souvent non inclus pour la création si auto-généré
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'duree_estimee': dureeEstimee,
      'objectifs': objectifs,
      'prerequis': prerequis,
      'actif': actif,
      // 'created_at': createdAt.toIso8601String(), // géré par BD
      // 'updated_at': updatedAt?.toIso8601String(), // géré par BD
      'created_by': createdBy,
    };
  }

  ChapitreModel copyWith({
    int? id,
    int? matiereId,
    String? niveauCode,
    String? serieCode,
    String? nom,
    String? description,
    int? ordre,
    int? dureeEstimee,
    List<String>? objectifs,
    List<String>? prerequis,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ChapitreModel(
      id: id ?? this.id,
      matiereId: matiereId ?? this.matiereId,
      niveauCode: niveauCode ?? this.niveauCode,
      serieCode: serieCode ?? this.serieCode,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      ordre: ordre ?? this.ordre,
      dureeEstimee: dureeEstimee ?? this.dureeEstimee,
      objectifs: objectifs ?? this.objectifs,
      prerequis: prerequis ?? this.prerequis,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}