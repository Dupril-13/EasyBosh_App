import 'package:equatable/equatable.dart';

/// Modèle pour les matières
class MatiereModel extends Equatable {
  final int id;
  final String nom;
  final String code;
  final String? description;
  final String couleur;
  final String icone;
  final String type; // 'obligatoire', 'optionnelle', 'facultative'
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatiereModel({
    required this.id,
    required this.nom,
    required this.code,
    this.description,
    this.couleur = '#2196F3',
    this.icone = 'book',
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatiereModel.fromMap(Map<String, dynamic> map) {
    return MatiereModel(
      id: map['id'] as int,
      nom: map['nom'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      couleur: map['couleur'] as String? ?? '#2196F3',
      icone: map['icone'] as String? ?? 'book',
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'code': code,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, nom, code, description, couleur, icone, type, createdAt, updatedAt];
}

/// Modèle pour les chapitres
class ChapitreModel extends Equatable {
  final int id;
  final int matiereId;
  final String niveauCode;
  final String serieCode;
  final String typeContenu; // 'ecrit', 'video', 'audio'
  final String nom;
  final String? description;
  final int ordre;
  final int? dureeEstimee; // en minutes
  final List<String>? objectifs;
  final List<String>? prerequis;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const ChapitreModel({
    required this.id,
    required this.matiereId,
    required this.niveauCode,
    required this.serieCode,
    required this.typeContenu,
    required this.nom,
    this.description,
    required this.ordre,
    this.dureeEstimee,
    this.objectifs,
    this.prerequis,
    this.actif = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ChapitreModel.fromMap(Map<String, dynamic> map) {
    return ChapitreModel(
      id: map['id'] as int,
      matiereId: map['matiere_id'] as int,
      niveauCode: map['niveau_code'] as String,
      serieCode: map['serie_code'] as String,
      typeContenu: map['type_contenu'] as String,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      ordre: map['ordre'] as int,
      dureeEstimee: map['duree_estimee'] as int?,
      objectifs: map['objectifs'] != null
          ? List<String>.from(map['objectifs'])
          : null,
      prerequis: map['prerequis'] != null
          ? List<String>.from(map['prerequis'])
          : null,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matiere_id': matiereId,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'type_contenu': typeContenu,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'duree_estimee': dureeEstimee,
      'objectifs': objectifs,
      'prerequis': prerequis,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [
    id, matiereId, niveauCode, serieCode, typeContenu, nom, description,
    ordre, dureeEstimee, objectifs, prerequis, actif, createdAt, updatedAt, createdBy
  ];
}

/// Modèle pour les leçons
class LeconModel extends Equatable {
  final int id;
  final int chapitreId;
  final String nom;
  final String? description;
  final int ordre;
  final int? dureeEstimee; // en minutes

  // Contenu selon le type
  final String? contenuTexte; // Pour type 'ecrit'
  final String? fichierPdfUrl; // Pour type 'ecrit'
  final String? videoUrl; // Pour type 'video'
  final String? audioUrl; // Pour type 'audio'
  final String? miniatureUrl;

  // Métadonnées
  final int? tailleFichier; // en bytes
  final int? dureeMedia; // durée en secondes pour audio/vidéo
  final String? resolution; // pour vidéos
  final String? formatFichier;

  // Paramètres d'affichage
  final bool autoplay;
  final String? sousTitresUrl;
  final String? transcriptionUrl;

  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const LeconModel({
    required this.id,
    required this.chapitreId,
    required this.nom,
    this.description,
    required this.ordre,
    this.dureeEstimee,
    this.contenuTexte,
    this.fichierPdfUrl,
    this.videoUrl,
    this.audioUrl,
    this.miniatureUrl,
    this.tailleFichier,
    this.dureeMedia,
    this.resolution,
    this.formatFichier,
    this.autoplay = false,
    this.sousTitresUrl,
    this.transcriptionUrl,
    this.actif = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  /// Type de contenu de la leçon
  String get typeContenu {
    if (fichierPdfUrl != null || contenuTexte != null) return 'ecrit';
    if (videoUrl != null) return 'video';
    if (audioUrl != null) return 'audio';
    return 'ecrit';
  }

  /// URL principale du contenu
  String? get urlPrincipale {
    switch (typeContenu) {
      case 'ecrit':
        return fichierPdfUrl;
      case 'video':
        return videoUrl;
      case 'audio':
        return audioUrl;
      default:
        return null;
    }
  }

  /// A du contenu multimédia
  bool get hasMedia {
    return videoUrl != null || audioUrl != null;
  }

  /// Durée formatée
  String get dureeFormatee {
    if (dureeMedia != null) {
      final minutes = dureeMedia! ~/ 60;
      final secondes = dureeMedia! % 60;
      return '${minutes}:${secondes.toString().padLeft(2, '0')}';
    } else if (dureeEstimee != null) {
      return '${dureeEstimee} min';
    }
    return '';
  }

  /// Taille formatée
  String get tailleFormatee {
    if (tailleFichier != null) {
      if (tailleFichier! < 1024 * 1024) {
        return '${(tailleFichier! / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(tailleFichier! / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    return '';
  }

  factory LeconModel.fromMap(Map<String, dynamic> map) {
    return LeconModel(
      id: map['id'] as int,
      chapitreId: map['chapitre_id'] as int,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      ordre: map['ordre'] as int,
      dureeEstimee: map['duree_estimee'] as int?,
      contenuTexte: map['contenu_texte'] as String?,
      fichierPdfUrl: map['fichier_pdf_url'] as String?,
      videoUrl: map['video_url'] as String?,
      audioUrl: map['audio_url'] as String?,
      miniatureUrl: map['miniature_url'] as String?,
      tailleFichier: map['taille_fichier'] as int?,
      dureeMedia: map['duree_media'] as int?,
      resolution: map['resolution'] as String?,
      formatFichier: map['format_fichier'] as String?,
      autoplay: map['autoplay'] as bool? ?? false,
      sousTitresUrl: map['sous_titres_url'] as String?,
      transcriptionUrl: map['transcription_url'] as String?,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapitre_id': chapitreId,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'duree_estimee': dureeEstimee,
      'contenu_texte': contenuTexte,
      'fichier_pdf_url': fichierPdfUrl,
      'video_url': videoUrl,
      'audio_url': audioUrl,
      'miniature_url': miniatureUrl,
      'taille_fichier': tailleFichier,
      'duree_media': dureeMedia,
      'resolution': resolution,
      'format_fichier': formatFichier,
      'autoplay': autoplay,
      'sous_titres_url': sousTitresUrl,
      'transcription_url': transcriptionUrl,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [
    id, chapitreId, nom, description, ordre, dureeEstimee,
    contenuTexte, fichierPdfUrl, videoUrl, audioUrl, miniatureUrl,
    tailleFichier, dureeMedia, resolution, formatFichier,
    autoplay, sousTitresUrl, transcriptionUrl,
    actif, createdAt, updatedAt, createdBy
  ];
}

/// Modèle pour la progression des leçons
class LeconProgressionModel extends Equatable {
  final int id;
  final String userId;
  final int leconId;
  final bool commence;
  final bool termine;
  final int tempsPasse; // en secondes
  final int pourcentageProgression;
  final int dernierePosition;
  final String? notesPersonnelles;
  final Map<String, dynamic>? marquePages;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  const LeconProgressionModel({
    required this.id,
    required this.userId,
    required this.leconId,
    this.commence = false,
    this.termine = false,
    this.tempsPasse = 0,
    this.pourcentageProgression = 0,
    this.dernierePosition = 0,
    this.notesPersonnelles,
    this.marquePages,
    this.startedAt,
    this.completedAt,
    required this.updatedAt,
  });

  /// Temps formaté
  String get tempsFormate {
    final heures = tempsPasse ~/ 3600;
    final minutes = (tempsPasse % 3600) ~/ 60;
    final secondes = tempsPasse % 60;

    if (heures > 0) {
      return '${heures}h ${minutes}m ${secondes}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secondes}s';
    } else {
      return '${secondes}s';
    }
  }

  factory LeconProgressionModel.fromMap(Map<String, dynamic> map) {
    return LeconProgressionModel(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      leconId: map['lecon_id'] as int,
      commence: map['commence'] as bool? ?? false,
      termine: map['termine'] as bool? ?? false,
      tempsPasse: map['temps_passe'] as int? ?? 0,
      pourcentageProgression: map['pourcentage_progression'] as int? ?? 0,
      dernierePosition: map['derniere_position'] as int? ?? 0,
      notesPersonnelles: map['notes_personnelles'] as String?,
      marquePages: map['marque_pages'] as Map<String, dynamic>?,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lecon_id': leconId,
      'commence': commence,
      'termine': termine,
      'temps_passe': tempsPasse,
      'pourcentage_progression': pourcentageProgression,
      'derniere_position': dernierePosition,
      'notes_personnelles': notesPersonnelles,
      'marque_pages': marquePages,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LeconProgressionModel copyWith({
    int? id,
    String? userId,
    int? leconId,
    bool? commence,
    bool? termine,
    int? tempsPasse,
    int? pourcentageProgression,
    int? dernierePosition,
    String? notesPersonnelles,
    Map<String, dynamic>? marquePages,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return LeconProgressionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leconId: leconId ?? this.leconId,
      commence: commence ?? this.commence,
      termine: termine ?? this.termine,
      tempsPasse: tempsPasse ?? this.tempsPasse,
      pourcentageProgression: pourcentageProgression ?? this.pourcentageProgression,
      dernierePosition: dernierePosition ?? this.dernierePosition,
      notesPersonnelles: notesPersonnelles ?? this.notesPersonnelles,
      marquePages: marquePages ?? this.marquePages,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, leconId, commence, termine, tempsPasse,
    pourcentageProgression, dernierePosition, notesPersonnelles,
    marquePages, startedAt, completedAt, updatedAt
  ];
}