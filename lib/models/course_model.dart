class CourseModel {
  final int id;
  final int? chapitreId; // FK vers chapitres.id
  final String nom;
  final String? description;
  final Map<String, dynamic>? contenu; // JSONB
  final int ordre;
  final int? dureeEstimee; // en minutes?
  final String type; // ex: 'text_rich', 'video', 'pdf', 'quiz_ref'
  final String? urlMedia;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // UUID de l'utilisateur profile

  CourseModel({
    required this.id,
    this.chapitreId,
    required this.nom,
    this.description,
    this.contenu,
    required this.ordre,
    this.dureeEstimee,
    required this.type,
    this.urlMedia,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as int,
      chapitreId: map['chapitre_id'] as int?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      contenu: map['contenu'] != null ? Map<String, dynamic>.from(map['contenu'] as Map) : null,
      ordre: map['ordre'] as int? ?? 0,
      dureeEstimee: map['duree_estimee'] as int?,
      type: map['type'] as String? ?? 'text_rich',
      urlMedia: map['url_media'] as String?,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // Non inclus pour la création si auto-généré
      'chapitre_id': chapitreId,
      'nom': nom,
      'description': description,
      'contenu': contenu,
      'ordre': ordre,
      'duree_estimee': dureeEstimee,
      'type': type,
      'url_media': urlMedia,
      'actif': actif,
      // 'created_at': createdAt.toIso8601String(), // géré par BD
      // 'updated_at': updatedAt?.toIso8601String(), // géré par BD
      'created_by': createdBy,
    };
  }

  CourseModel copyWith({
    int? id,
    int? chapitreId,
    String? nom,
    String? description,
    Map<String, dynamic>? contenu,
    int? ordre,
    int? dureeEstimee,
    String? type,
    String? urlMedia,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CourseModel(
      id: id ?? this.id,
      chapitreId: chapitreId ?? this.chapitreId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      contenu: contenu ?? this.contenu,
      ordre: ordre ?? this.ordre,
      dureeEstimee: dureeEstimee ?? this.dureeEstimee,
      type: type ?? this.type,
      urlMedia: urlMedia ?? this.urlMedia,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}