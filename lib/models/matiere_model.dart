class MatiereModel {
  final int id;
  final String nom;
  final String code;
  final String? description;
  final String? couleur;
  final String? icone;
  final String type; // 'obligatoire', 'optionnelle', 'facultative'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MatiereModel({
    required this.id,
    required this.nom,
    required this.code,
    this.description,
    this.couleur,
    this.icone,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory MatiereModel.fromMap(Map<String, dynamic> map) {
    return MatiereModel(
      id: map['id'] as int? ?? 0, // Fournir une valeur par défaut ou gérer l'erreur
      nom: map['nom'] as String? ?? 'Nom indisponible', // Fournir une valeur par défaut
      code: map['code'] as String? ?? 'Code indisponible', // Fournir une valeur par défaut
      description: map['description'] as String?,
      couleur: map['couleur'] as String?,
      icone: map['icone'] as String?,
      type: map['type'] as String? ?? 'Type indisponible', // Fournir une valeur par défaut
      createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'nom': nom,
      'code': code, 
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
    };
  }

  MatiereModel copyWith({
    int? id,
    String? nom,
    String? code,
    String? description,
    String? couleur,
    String? icone,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatiereModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      code: code ?? this.code,
      description: description ?? this.description,
      couleur: couleur ?? this.couleur,
      icone: icone ?? this.icone,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
