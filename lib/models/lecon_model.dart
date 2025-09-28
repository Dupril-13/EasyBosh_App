class LeconModel {
  final int id;
  final int? chapitreId; // FK vers chapitres.id
  final String nom;
  final String? description;
  final Map<String, dynamic>? contenu; // JSONB
  final int ordre; // Ordre global/primaire
  final Map<String, int>? ordreParType; // Nouveau champ pour les ordres spécifiques au type
  final int? dureeEstimee; // en minutes?
  final String type; // ex: 'text_rich', 'video', 'pdf', 'quiz_ref'
  final String? urlMedia;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // UUID de l'utilisateur profile

  LeconModel({
    required this.id,
    this.chapitreId,
    required this.nom,
    this.description,
    this.contenu,
    required this.ordre,
    this.ordreParType, // Ajouté au constructeur
    this.dureeEstimee,
    required this.type,
    this.urlMedia,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory LeconModel.fromMap(Map<String, dynamic> map) {
    Map<String, int>? parsedOrdreParType;
    if (map['ordre_par_type'] != null) {
      try {
        parsedOrdreParType = (map['ordre_par_type'] as Map).map(
          (key, value) => MapEntry(key.toString(), int.parse(value.toString())),
        );
      } catch (e) {
        print("Erreur de parsing pour ordre_par_type: $e. Valeur reçue: ${map['ordre_par_type']}");
        parsedOrdreParType = null; 
      }
    }

    return LeconModel(
      id: map['id'] as int,
      chapitreId: map['chapitre_id'] as int?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      contenu: map['contenu'] != null ? Map<String, dynamic>.from(map['contenu'] as Map) : null,
      ordre: map['ordre'] as int? ?? 0,
      ordreParType: parsedOrdreParType, // Champ mis à jour
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
      // 'id': id, 
      'chapitre_id': chapitreId,
      'nom': nom,
      'description': description,
      'contenu': contenu,
      'ordre': ordre,
      'ordre_par_type': ordreParType, // Champ mis à jour (nom de la colonne SQL)
      'duree_estimee': dureeEstimee,
      'type': type,
      'url_media': urlMedia,
      'actif': actif,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    final map = toMap();
    map.remove('created_by'); 
    map.remove('chapitre_id'); 
    map.remove('id'); // L'ID est utilisé dans l'eq(), pas dans le corps de l'update
    // On pourrait vouloir mettre à jour `updated_at` manuellement si la BD ne le fait pas par trigger
    // map['updated_at'] = DateTime.now().toIso8601String(); 
    return map;
  }


  LeconModel copyWith({
    int? id,
    int? chapitreId,
    String? nom,
    String? description,
    Map<String, dynamic>? contenu,
    int? ordre,
    Map<String, int>? ordreParType, 
    bool setToNullOrdreParType = false, 
    int? dureeEstimee,
    String? type,
    String? urlMedia,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool setToNullCreatedBy = false,
  }) {
    return LeconModel(
      id: id ?? this.id,
      chapitreId: chapitreId ?? this.chapitreId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      contenu: contenu ?? this.contenu,
      ordre: ordre ?? this.ordre,
      ordreParType: setToNullOrdreParType ? null : (ordreParType ?? this.ordreParType), 
      dureeEstimee: dureeEstimee ?? this.dureeEstimee,
      type: type ?? this.type,
      urlMedia: urlMedia ?? this.urlMedia,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: setToNullCreatedBy? null : (createdBy ?? this.createdBy),
    );
  }
}