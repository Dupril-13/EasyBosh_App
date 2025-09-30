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
  final DateTime? createdAt; // MODIFIÉ: rendu nullable
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
    this.createdAt, // MODIFIÉ: retiré 'required'
    this.updatedAt,
    this.createdBy,
  });

  factory ChapitreModel.fromMap(Map<String, dynamic> map) {
    final idValue = map['id'];
    if (idValue == null || !(idValue is int)) {
      throw ArgumentError('ChapitreModel.fromMap: Le champ "id" est manquant, null ou n\'est pas un entier. Valeur reçue: $idValue');
    }

    final nomValue = map['nom'];
    if (nomValue == null || !(nomValue is String) || nomValue.isEmpty) {
      throw ArgumentError('ChapitreModel.fromMap: Le champ "nom" est manquant, null ou vide. Valeur reçue: $nomValue');
    }

    int parsedOrdre = 0; 
    final ordreValue = map['ordre'];
    if (ordreValue != null) {
      if (ordreValue is int) {
        parsedOrdre = ordreValue;
      } else if (ordreValue is String) {
        parsedOrdre = int.tryParse(ordreValue) ?? 0;
      } else if (ordreValue is double) { 
          parsedOrdre = ordreValue.toInt();
      }
    }
    
    // Gérer createdAt (maintenant nullable)
    final createdAtValue = map['created_at'] as String?;
    DateTime? parsedCreatedAt;
    if (createdAtValue != null) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtValue);
      } catch (e) {
        print('ChapitreModel.fromMap: AVERTISSEMENT - Impossible de parser la chaîne "created_at": "$createdAtValue". createdAt sera null. Erreur: $e');
      }
    }

    return ChapitreModel(
      id: idValue as int, 
      matiereId: map['matiere_id'] as int?,
      niveauCode: map['niveau_code'] as String?,
      serieCode: map['serie_code'] as String?,
      nom: nomValue as String, 
      description: map['description'] as String?,
      ordre: parsedOrdre, 
      dureeEstimee: map['duree_estimee'] as int?,
      objectifs: (map['objectifs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      prerequis: (map['prerequis'] as List<dynamic>?)?.map((e) => e as String).toList(),
      actif: map['actif'] as bool? ?? true, 
      createdAt: parsedCreatedAt, 
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
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
      // 'id', 'created_at', 'updated_at' sont gérés par la BD ou non pertinents pour l'insert/update direct
    };

    if (createdBy != null) {
      map['created_by'] = createdBy;
    }
    return map;
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