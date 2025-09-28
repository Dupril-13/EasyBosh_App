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
      id: map['id'] as int,
      nom: map['nom'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      couleur: map['couleur'] as String?,
      icone: map['icone'] as String?,
      type: map['type'] as String,
      createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ID is typically used in .eq() for updates, not in the body
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      // createdAt and updatedAt are usually handled by DB defaults/triggers
    };
  }

  // Used for creating a new record, Supabase handles id, created_at, updated_at
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

  // Used for updating an existing record
  Map<String, dynamic> toMapForUpdate() {
    return {
      'nom': nom,
      'code': code, // Be cautious if allowing code (UNIQUE) to be updated
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      // 'updated_at': DateTime.now().toIso8601String(), // Optionally force update timestamp
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
