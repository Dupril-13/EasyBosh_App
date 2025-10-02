import 'package:flutter/foundation.dart';

// Énumération pour le type d'épreuve (correspondra aux valeurs string de la BDD)
enum EpreuveType {
  ancienSujet,      // ex: 'ancien_sujet' en BDD
  sujetCollege,     // ex: 'sujet_college' en BDD
  examenBlanc,      // ex: 'examen_blanc' en BDD
  epreuveExclusive  // ex: 'exclusive' en BDD (si vous l'utilisez)
}

// Énumération pour le statut de l'épreuve (correspondra aux valeurs string de la BDD)
enum EpreuveStatut {
  brouillon,   // 'brouillon'
  publiee,     // 'publiee'
  programmee,  // 'programmee'
  archivee     // 'archivee'
}

// Énumération pour les types d'examen officiels (utilisée dans le formulaire)
enum TypeExamenOfficiel {
  bepc,
  probatoire,
  baccalaureat
}

// Classe représentant une épreuve, alignée sur votre table Supabase `epreuves`
class Epreuve {
  final int? id; // Nullable pour la création, non-null pour les épreuves existantes
  final DateTime? createdAt; // epreuves.created_at
  final String? createdBy; // epreuves.created_by (uuid de l'utilisateur)
  final DateTime? updatedAt; // epreuves.updated_at

  String nom; // epreuves.nom (Titre de l'épreuve)
  EpreuveType typeEpreuve; // Mappé depuis/vers epreuves.type (String)
  int matiereId; // epreuves.matiere_id
  String niveauCode; // epreuves.niveau_code (ex: '3eme', '1ere', 'tle')
  List<String> seriesCodes; // epreuves.series_codes (TEXT[]), ex: ['C', 'D']
  int dureeMinutes; // epreuves.duree
  double bareme;    // epreuves.bareme
  String? description; // epreuves.description (peut servir de consignes générales)
  bool actif; // epreuves.actif (utilisé pour dériver publiee/archivee si statut n'est pas utilisé directement)
  
  String? sujetPdfUrl; // epreuves.fichier_url 
  String? corrigePdfUrl; // epreuves.corrige_url

  int? anneeExamen; // epreuves.annee
  String? sessionExamen; // epreuves.session

  String? nomEtablissement; // epreuves.nom_etablissement
  String? villeEtablissement; // epreuves.ville_etablissement
  DateTime? dateCompositionCollege; // epreuves.date_composition_college

  EpreuveStatut statut; // epreuves.statut (ex: 'brouillon', 'publiee')
  DateTime? datePublicationProgrammee; // epreuves.date_publication_programmee

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

  static String typeToString(EpreuveType type) { // Made public
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

  static String statutToString(EpreuveStatut statut) { // Made public
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
    );
  }

  Map<String, dynamic> toMap() {
    final mapData = {
      'nom': nom,
      'type': typeToString(typeEpreuve), // Using public method
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
      'statut': statutToString(statut), // Using public method
      'date_publication_programmee': datePublicationProgrammee?.toIso8601String(),
    };
    if (id != null) {
      mapData['id'] = id; // Inclure l'ID pour les mises à jour
    }
    if (createdBy != null) {
      mapData['created_by'] = createdBy;
    }
    return mapData;
  }

  String get typeEpreuveDisplay {
    switch (typeEpreuve) {
      case EpreuveType.ancienSujet: return 'Ancien Sujet d\'Examen';
      case EpreuveType.sujetCollege: return 'Sujet de Collège Connu';
      case EpreuveType.examenBlanc: return 'Examen Blanc';
      case EpreuveType.epreuveExclusive: return 'Épreuve Exclusive';
    }
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

  String get niveauScolaireDisplay => niveauCode; 
}

// Helper classes pour les Dropdowns, pour stocker à la fois le code/id et le nom affichable
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
