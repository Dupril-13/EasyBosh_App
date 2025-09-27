class MatiereModel {
  final int id;
  final String nom;
  final String code;
  final String? description;
  final String? couleur;
  final String? icone;
  final String type; // 'obligatoire', 'optionnelle', 'facultative'
  final DateTime? createdAt; // Ajouté
  final DateTime? updatedAt; // Ajouté

  MatiereModel({
    required this.id,
    required this.nom,
    required this.code,
    this.description,
    this.couleur,
    this.icone,
    required this.type,
    this.createdAt, // Ajouté
    this.updatedAt, // Ajouté
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
      // Gérer la conversion de String (ISO 8601) en DateTime pour les champs de Supabase
      createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    // Pour l'insertion, Supabase gère l'ID, created_at, et updated_at (si DEFAULT now() ou trigger)
    // Pour la mise à jour, on fournit l'ID dans la clause .eq(), et on peut mettre à jour les autres champs.
    // updated_at peut être mis à jour par un trigger Supabase ou explicitement.
    return {
      // 'id': id, // L'ID n'est généralement pas inclus dans le payload d'insertion/mise à jour si géré par la DB ou dans la clause .eq()
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      // Pour l'écriture vers Supabase, DateTime doit être converti en String ISO 8601
      // Si createdAt est géré par la DB (DEFAULT now()), on ne l'envoie pas à la création.
      // Si updatedAt est géré par la DB (trigger ou DEFAULT now()), on ne l'envoie pas à la MàJ.
      // Pour l'instant, on les inclut s'ils sont définis, utile si on veut les forcer.
      // Mais il est souvent mieux de laisser la DB les gérer.
      // Commentons-les pour l'instant, en supposant que la DB les gère.
      // 'created_at': createdAt?.toIso8601String(),
      // 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Optionnel: une méthode toMap pour l'insertion où l'ID n'est pas requis
  Map<String, dynamic> toMapForInsert() {
    return {
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      // createdAt et updatedAt sont gérés par Supabase avec DEFAULT now()
    };
  }

  // Optionnel: une méthode toMap pour la mise à jour
  Map<String, dynamic> toMapForUpdate() {
    return {
      'nom': nom,
      'code': code, // Le code est UNIQUE, attention si on permet de le modifier
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      // 'updated_at': DateTime.now().toIso8601String(), // Forcer la mise à jour de updated_at
    };
  }
}
