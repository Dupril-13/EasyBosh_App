import 'package:flutter/foundation.dart';

enum EpreuveType {
  ancienSujet,
  sujetCollege,
  examenBlanc,
  epreuveExclusive
}

enum EpreuveStatut {
  brouillon,
  publiee,
  programmee,
  archivee
}

enum TypeExamenOfficiel {
  bepc,
  probatoire,
  baccalaureat
}

class Epreuve {
  final int? id;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;

  String nom;
  EpreuveType typeEpreuve;
  int matiereId;
  String niveauCode;
  List<String> seriesCodes;
  int dureeMinutes;
  double bareme;
  String? description;
  bool actif;
  
  String? sujetPdfUrl;
  String? corrigePdfUrl;

  int? anneeExamen;
  String? sessionExamen;

  String? nomEtablissement;
  String? villeEtablissement;
  DateTime? dateCompositionCollege;

  EpreuveStatut statut;
  DateTime? datePublicationProgrammee;

  final String? matiereNom;
  final String? niveauNom;

  Epreuve({
    this.id,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    required this.nom,
    required this.typeEpreuve,
    required this.matiereId,
    required this.niveauCode,
    required this.seriesCodes,
    required this.dureeMinutes,
    required this.bareme,
    this.description,
    this.actif = true, 
    this.sujetPdfUrl,
    this.corrigePdfUrl,
    this.anneeExamen,
    this.sessionExamen,
    this.nomEtablissement,
    this.villeEtablissement,
    this.dateCompositionCollege,
    this.statut = EpreuveStatut.brouillon,
    this.datePublicationProgrammee,
    this.matiereNom,
    this.niveauNom,
  });

  static EpreuveType _typeFromString(String? typeString) {
    switch (typeString) {
      case 'ancien_sujet': return EpreuveType.ancienSujet;
      case 'sujet_college': return EpreuveType.sujetCollege;
      case 'examen_blanc': return EpreuveType.examenBlanc;
      case 'exclusive': return EpreuveType.epreuveExclusive;
      default: return EpreuveType.examenBlanc;
    }
  }

  static String typeToString(EpreuveType type) {
    switch (type) {
      case EpreuveType.ancienSujet: return 'ancien_sujet';
      case EpreuveType.sujetCollege: return 'sujet_college';
      case EpreuveType.examenBlanc: return 'examen_blanc';
      case EpreuveType.epreuveExclusive: return 'exclusive';
    }
  }

  static EpreuveStatut _statutFromString(String? statutString) {
    switch (statutString) {
      case 'brouillon': return EpreuveStatut.brouillon;
      case 'publiee': return EpreuveStatut.publiee;
      case 'programmee': return EpreuveStatut.programmee;
      case 'archivee': return EpreuveStatut.archivee;
      default: return EpreuveStatut.brouillon;
    }
  }

  static String statutToString(EpreuveStatut statut) {
    switch (statut) {
      case EpreuveStatut.brouillon: return 'brouillon';
      case EpreuveStatut.publiee: return 'publiee';
      case EpreuveStatut.programmee: return 'programmee';
      case EpreuveStatut.archivee: return 'archivee';
    }
  }
  
  static List<String> _seriesCodesFromDb(dynamic dbValue) {
    if (dbValue is List) {
      return List<String>.from(dbValue.map((item) => item.toString()));
    }
    if (dbValue is String && dbValue.isNotEmpty) {
        return [dbValue]; 
    }
    return [];
  }

  factory Epreuve.fromMap(Map<String, dynamic> map) {
    return Epreuve(
      id: map['id'] as int?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      createdBy: map['created_by'] as String?,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      nom: map['nom'] as String,
      typeEpreuve: _typeFromString(map['type'] as String?),
      matiereId: map['matiere_id'] as int,
      niveauCode: map['niveau_code'] as String,
      seriesCodes: _seriesCodesFromDb(map['series_codes']), 
      dureeMinutes: map['duree'] as int,
      bareme: (map['bareme'] as num).toDouble(),
      description: map['description'] as String?,
      actif: map['actif'] as bool? ?? true,
      sujetPdfUrl: map['fichier_url'] as String?,
      corrigePdfUrl: map['corrige_url'] as String?,
      anneeExamen: map['annee'] as int?,
      sessionExamen: map['session'] as String?,
      nomEtablissement: map['nom_etablissement'] as String?,
      villeEtablissement: map['ville_etablissement'] as String?,
      dateCompositionCollege: map['date_composition_college'] != null ? DateTime.parse(map['date_composition_college'] as String) : null,
      statut: _statutFromString(map['statut'] as String?),
      datePublicationProgrammee: map['date_publication_programmee'] != null ? DateTime.parse(map['date_publication_programmee'] as String) : null,
      matiereNom: map['matieres'] != null ? map['matieres']['nom'] as String? : null,
      niveauNom: map['niveaux'] != null ? map['niveaux']['nom'] as String? : null,
    );
  }

  Map<String, dynamic> toMap() {
    final mapData = {
      'nom': nom,
      'type': typeToString(typeEpreuve),
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'series_codes': seriesCodes,
      'duree': dureeMinutes,
      'bareme': bareme,
      'description': description,
      'actif': (statut == EpreuveStatut.publiee || statut == EpreuveStatut.programmee),
      'fichier_url': sujetPdfUrl,
      'corrige_url': corrigePdfUrl,
      'annee': anneeExamen,
      'session': sessionExamen,
      'nom_etablissement': nomEtablissement,
      'ville_etablissement': villeEtablissement,
      'date_composition_college': dateCompositionCollege?.toIso8601String(),
      'statut': statutToString(statut),
      'date_publication_programmee': datePublicationProgrammee?.toIso8601String(),
    };
    if (id != null) mapData['id'] = id;
    if (createdBy != null) mapData['created_by'] = createdBy;
    return mapData;
  }

  static String statutToStringDisplay(EpreuveStatut statut) {
    switch (statut) {
      case EpreuveStatut.brouillon: return 'Brouillon';
      case EpreuveStatut.publiee: return 'Publiée';
      case EpreuveStatut.programmee: return 'Programmée';
      case EpreuveStatut.archivee: return 'Archivée';
    }
  }

  static String typeExamenOfficielToString(TypeExamenOfficiel type) {
    switch (type) {
      case TypeExamenOfficiel.bepc: return 'BEPC';
      case TypeExamenOfficiel.probatoire: return 'Probatoire';
      case TypeExamenOfficiel.baccalaureat: return 'Baccalauréat';
    }
  }

  static TypeExamenOfficiel? stringToTypeExamenOfficiel(String? sessionString) {
    if (sessionString == null) return null;
    switch (sessionString.toUpperCase()) {
      case 'BEPC': return TypeExamenOfficiel.bepc;
      case 'PROBATOIRE': return TypeExamenOfficiel.probatoire;
      case 'BACCALAURÉAT':
      case 'BACCALAUREAT': return TypeExamenOfficiel.baccalaureat;
      default: return null;
    }
  }

  String get niveauScolaireDisplay => niveauNom ?? niveauCode;
  String get matiereDisplay => matiereNom ?? 'Matière ID: $matiereId';
}

extension EpreuveTypeExtension on EpreuveType {
  String get displayName {
    switch (this) {
      case EpreuveType.ancienSujet: return 'Ancien Sujet d\'Examen';
      case EpreuveType.sujetCollege: return 'Sujet de Collège Connu';
      case EpreuveType.examenBlanc: return 'Examen Blanc';
      case EpreuveType.epreuveExclusive: return 'Épreuve Exclusive';
    }
  }
}

class NiveauSelectionItem {
  final String code;
  final String nomDisplay;
  NiveauSelectionItem({required this.code, required this.nomDisplay});
  @override bool operator ==(Object other) => identical(this, other) || other is NiveauSelectionItem && runtimeType == other.runtimeType && code == other.code;
  @override int get hashCode => code.hashCode;
}

class SerieSelectionItem {
  final String code;
  final String nomDisplay;
  SerieSelectionItem({required this.code, required this.nomDisplay});
  @override bool operator ==(Object other) => identical(this, other) || other is SerieSelectionItem && runtimeType == other.runtimeType && code == other.code;
  @override int get hashCode => code.hashCode;
}

class MatiereSelectionItem {
  final int id;
  final String nomDisplay;
  MatiereSelectionItem({required this.id, required this.nomDisplay});
  @override bool operator ==(Object other) => identical(this, other) || other is MatiereSelectionItem && runtimeType == other.runtimeType && id == other.id;
  @override int get hashCode => id.hashCode;
}
