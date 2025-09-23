// lib/models/matiere_model.dart
import 'package:flutter/material.dart';

class MatiereModel {
  final int id;
  final String nom;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> niveaux;
  final List<String> series;
  final List<ChapitreModel> chapitres;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatiereModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.icon,
    required this.color,
    required this.niveaux,
    required this.series,
    required this.chapitres,
    required this.createdAt,
    required this.updatedAt,
  });

  // Conversion depuis Map (pour Supabase)
  factory MatiereModel.fromMap(Map<String, dynamic> map) {
    return MatiereModel(
      id: map['id'] ?? 0,
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconFromString(map['icon'] ?? 'book'),
      color: _getColorFromString(map['color'] ?? 'blue'),
      niveaux: List<String>.from(map['niveaux'] ?? []),
      series: List<String>.from(map['series'] ?? []),
      chapitres: (map['chapitres'] as List?)
          ?.map((c) => ChapitreModel.fromMap(c))
          .toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Conversion vers Map (pour Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'color': _getStringFromColor(color),
      'niveaux': niveaux,
      'series': series,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Utilitaires pour les icônes
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'functions': return Icons.functions;
      case 'science': return Icons.science;
      case 'science_outlined': return Icons.science_outlined;
      case 'menu_book': return Icons.menu_book;
      case 'language': return Icons.language;
      case 'public': return Icons.public;
      case 'map': return Icons.map;
      case 'psychology': return Icons.psychology;
      case 'eco': return Icons.eco;
      case 'computer': return Icons.computer;
      case 'gavel': return Icons.gavel;
      case 'sports_soccer': return Icons.sports_soccer;
      default: return Icons.book;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.functions) return 'functions';
    if (icon == Icons.science) return 'science';
    if (icon == Icons.science_outlined) return 'science_outlined';
    if (icon == Icons.menu_book) return 'menu_book';
    if (icon == Icons.language) return 'language';
    if (icon == Icons.public) return 'public';
    if (icon == Icons.map) return 'map';
    if (icon == Icons.psychology) return 'psychology';
    if (icon == Icons.eco) return 'eco';
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.gavel) return 'gavel';
    if (icon == Icons.sports_soccer) return 'sports_soccer';
    return 'book';
  }

  // Utilitaires pour les couleurs
  static Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'brown': return Colors.brown;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'amber': return Colors.amber;
      case 'deepOrange': return Colors.deepOrange;
      default: return Colors.blue;
    }
  }

  static String _getStringFromColor(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.green) return 'green';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.red) return 'red';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.indigo) return 'indigo';
    if (color == Colors.amber) return 'amber';
    if (color == Colors.deepOrange) return 'deepOrange';
    return 'blue';
  }

  // Copie avec modifications
  MatiereModel copyWith({
    int? id,
    String? nom,
    String? description,
    IconData? icon,
    Color? color,
    List<String>? niveaux,
    List<String>? series,
    List<ChapitreModel>? chapitres,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatiereModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      niveaux: niveaux ?? this.niveaux,
      series: series ?? this.series,
      chapitres: chapitres ?? this.chapitres,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Statistiques utiles
  int get nombreChapitres => chapitres.length;
  int get nombreLecons => chapitres.fold(0, (sum, chapitre) => sum + chapitre.nombreLecons);
  double get progressionMoyenne => chapitres.isEmpty
      ? 0.0
      : chapitres.fold(0.0, (sum, chapitre) => sum + chapitre.progression) / chapitres.length;

  @override
  String toString() {
    return 'MatiereModel(id: $id, nom: $nom, chapitres: ${nombreChapitres})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatiereModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Modèle Chapitre
class ChapitreModel {
  final int id;
  final int matiereId;
  final String nom;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulte; // 'Facile', 'Moyen', 'Difficile'
  final int dureeEstimeeMinutes;
  final double progression; // 0.0 à 1.0
  final List<LeconModel> lecons;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChapitreModel({
    required this.id,
    required this.matiereId,
    required this.nom,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulte,
    required this.dureeEstimeeMinutes,
    required this.progression,
    required this.lecons,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChapitreModel.fromMap(Map<String, dynamic> map) {
    return ChapitreModel(
      id: map['id'] ?? 0,
      matiereId: map['matiere_id'] ?? 0,
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      icon: MatiereModel._getIconFromString(map['icon'] ?? 'book'),
      color: MatiereModel._getColorFromString(map['color'] ?? 'blue'),
      difficulte: map['difficulte'] ?? 'Moyen',
      dureeEstimeeMinutes: map['duree_estimee_minutes'] ?? 0,
      progression: (map['progression'] ?? 0.0).toDouble(),
      lecons: (map['lecons'] as List?)
          ?.map((l) => LeconModel.fromMap(l))
          .toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matiere_id': matiereId,
      'nom': nom,
      'description': description,
      'icon': MatiereModel._getStringFromIcon(icon),
      'color': MatiereModel._getStringFromColor(color),
      'difficulte': difficulte,
      'duree_estimee_minutes': dureeEstimeeMinutes,
      'progression': progression,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Statistiques utiles
  int get nombreLecons => lecons.length;
  String get dureeEstimeeTexte {
    final heures = dureeEstimeeMinutes ~/ 60;
    final minutes = dureeEstimeeMinutes % 60;
    if (heures == 0) return '${minutes}min';
    if (minutes == 0) return '${heures}h';
    return '${heures}h${minutes}min';
  }

  Color get difficulteColor {
    switch (difficulte) {
      case 'Facile': return Colors.green;
      case 'Moyen': return Colors.orange;
      case 'Difficile': return Colors.red;
      default: return Colors.grey;
    }
  }

  ChapitreModel copyWith({
    int? id,
    int? matiereId,
    String? nom,
    String? description,
    IconData? icon,
    Color? color,
    String? difficulte,
    int? dureeEstimeeMinutes,
    double? progression,
    List<LeconModel>? lecons,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChapitreModel(
      id: id ?? this.id,
      matiereId: matiereId ?? this.matiereId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      difficulte: difficulte ?? this.difficulte,
      dureeEstimeeMinutes: dureeEstimeeMinutes ?? this.dureeEstimeeMinutes,
      progression: progression ?? this.progression,
      lecons: lecons ?? this.lecons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChapitreModel(id: $id, nom: $nom, lecons: ${nombreLecons})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapitreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Modèle Leçon
class LeconModel {
  final int id;
  final int chapitreId;
  final String titre;
  final String description;
  final String contenu; // Contenu de la leçon (markdown/html)
  final String type; // 'video', 'texte', 'interactive', 'quiz'
  final String? videoUrl;
  final String? documentUrl;
  final int dureeEstimeeMinutes;
  final int ordre; // Ordre dans le chapitre
  final bool estComplete;
  final DateTime? dateCompletion;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeconModel({
    required this.id,
    required this.chapitreId,
    required this.titre,
    required this.description,
    required this.contenu,
    required this.type,
    this.videoUrl,
    this.documentUrl,
    required this.dureeEstimeeMinutes,
    required this.ordre,
    required this.estComplete,
    this.dateCompletion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeconModel.fromMap(Map<String, dynamic> map) {
    return LeconModel(
      id: map['id'] ?? 0,
      chapitreId: map['chapitre_id'] ?? 0,
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      contenu: map['contenu'] ?? '',
      type: map['type'] ?? 'texte',
      videoUrl: map['video_url'],
      documentUrl: map['document_url'],
      dureeEstimeeMinutes: map['duree_estimee_minutes'] ?? 0,
      ordre: map['ordre'] ?? 0,
      estComplete: map['est_complete'] ?? false,
      dateCompletion: map['date_completion'] != null
          ? DateTime.parse(map['date_completion'])
          : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapitre_id': chapitreId,
      'titre': titre,
      'description': description,
      'contenu': contenu,
      'type': type,
      'video_url': videoUrl,
      'document_url': documentUrl,
      'duree_estimee_minutes': dureeEstimeeMinutes,
      'ordre': ordre,
      'est_complete': estComplete,
      'date_completion': dateCompletion?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Propriétés utiles
  String get dureeEstimeeTexte {
    final heures = dureeEstimeeMinutes ~/ 60;
    final minutes = dureeEstimeeMinutes % 60;
    if (heures == 0) return '${minutes}min';
    if (minutes == 0) return '${heures}h';
    return '${heures}h${minutes}min';
  }

  IconData get typeIcon {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'texte': return Icons.article_outlined;
      case 'interactive': return Icons.touch_app;
      case 'quiz': return Icons.quiz_outlined;
      default: return Icons.description;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'video': return Colors.red;
      case 'texte': return Colors.blue;
      case 'interactive': return Colors.purple;
      case 'quiz': return Colors.green;
      default: return Colors.grey;
    }
  }

  LeconModel copyWith({
    int? id,
    int? chapitreId,
    String? titre,
    String? description,
    String? contenu,
    String? type,
    String? videoUrl,
    String? documentUrl,
    int? dureeEstimeeMinutes,
    int? ordre,
    bool? estComplete,
    DateTime? dateCompletion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeconModel(
      id: id ?? this.id,
      chapitreId: chapitreId ?? this.chapitreId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      contenu: contenu ?? this.contenu,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      dureeEstimeeMinutes: dureeEstimeeMinutes ?? this.dureeEstimeeMinutes,
      ordre: ordre ?? this.ordre,
      estComplete: estComplete ?? this.estComplete,
      dateCompletion: dateCompletion ?? this.dateCompletion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LeconModel(id: $id, titre: $titre, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeconModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}