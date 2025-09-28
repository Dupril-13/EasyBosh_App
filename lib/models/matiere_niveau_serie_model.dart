class MatiereNiveauSerieModel {
  final int id;
  final int matiereId;
  final String niveauCode;
  final String serieCode;
  final int coefficient;
  final bool obligatoire;

  MatiereNiveauSerieModel({
    required this.id,
    required this.matiereId,
    required this.niveauCode,
    required this.serieCode,
    required this.coefficient,
    required this.obligatoire,
  });

  factory MatiereNiveauSerieModel.fromMap(Map<String, dynamic> map) {
    return MatiereNiveauSerieModel(
      id: map['id'] as int,
      matiereId: map['matiere_id'] as int,
      niveauCode: map['niveau_code'] as String,
      serieCode: map['serie_code'] as String,
      coefficient: map['coefficient'] as int? ?? 1,
      obligatoire: map['obligatoire'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'coefficient': coefficient,
      'obligatoire': obligatoire,
    };
  }

  MatiereNiveauSerieModel copyWith({
    int? id,
    int? matiereId,
    String? niveauCode,
    String? serieCode,
    int? coefficient,
    bool? obligatoire,
  }) {
    return MatiereNiveauSerieModel(
      id: id ?? this.id,
      matiereId: matiereId ?? this.matiereId,
      niveauCode: niveauCode ?? this.niveauCode,
      serieCode: serieCode ?? this.serieCode,
      coefficient: coefficient ?? this.coefficient,
      obligatoire: obligatoire ?? this.obligatoire,
    );
  }
}
