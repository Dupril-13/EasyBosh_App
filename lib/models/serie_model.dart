class SerieModel {
  final int id;
  final String code;
  final String nom;
  final String? description;
  final String type; // ex: "Générale", "Technique"

  SerieModel({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    required this.type,
  });

  factory SerieModel.fromMap(Map<String, dynamic> map) {
    return SerieModel(
      id: map['id'] as int,
      code: map['code'] as String,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'description': description,
      'type': type,
    };
  }
}