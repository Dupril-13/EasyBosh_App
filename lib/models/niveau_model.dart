class NiveauModel {
  final int id;
  final String code;
  final String nom;
  final String? description;
  final int ordre;

  NiveauModel({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    required this.ordre,
  });

  factory NiveauModel.fromMap(Map<String, dynamic> map) {
    return NiveauModel(
      id: map['id'] as int,
      code: map['code'] as String,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      ordre: map['ordre'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'description': description,
      'ordre': ordre,
    };
  }
}