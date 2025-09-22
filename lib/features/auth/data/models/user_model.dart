import 'package:equatable/equatable.dart';

/// Modèle utilisateur pour EasyBosh
class UserModel extends Equatable {
  final String uid;
  final String email;
  final String role; // 'etudiant', 'enseignant', 'admin'
  final String? nom;
  final String? prenom;
  final String? niveauCode; // '3eme', '1ere', 'tle'
  final String? serieCode; // 'A', 'C', 'D', 'TI', etc.
  final String? telephone;
  final DateTime? dateNaissance;
  final bool emailVerified;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.nom,
    this.prenom,
    this.niveauCode,
    this.serieCode,
    this.telephone,
    this.dateNaissance,
    this.emailVerified = false,
    this.actif = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Getters utiles
  String get nomComplet {
    if (nom != null && prenom != null) {
      return '$prenom $nom';
    } else if (nom != null) {
      return nom!;
    } else if (prenom != null) {
      return prenom!;
    }
    return email.split('@').first;
  }

  String get initiales {
    if (nom != null && prenom != null) {
      return '${prenom!.substring(0, 1)}${nom!.substring(0, 1)}'.toUpperCase();
    } else if (nom != null) {
      return nom!.substring(0, 1).toUpperCase();
    } else if (prenom != null) {
      return prenom!.substring(0, 1).toUpperCase();
    }
    return email.substring(0, 1).toUpperCase();
  }

  bool get isEtudiant => role == 'etudiant';
  bool get isEnseignant => role == 'enseignant';
  bool get isAdmin => role == 'admin';
  bool get isStaff => isEnseignant || isAdmin;

  /// Vérification de profil complet pour les étudiants
  bool get isProfileComplete {
    if (isEtudiant) {
      return nom != null &&
          prenom != null &&
          niveauCode != null &&
          serieCode != null;
    }
    return nom != null && prenom != null;
  }

  /// Factory depuis Map (pour Supabase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      nom: map['nom'] as String?,
      prenom: map['prenom'] as String?,
      niveauCode: map['niveau_code'] as String?,
      serieCode: map['serie_code'] as String?,
      telephone: map['telephone'] as String?,
      dateNaissance: map['date_naissance'] != null
          ? DateTime.parse(map['date_naissance'] as String)
          : null,
      emailVerified: map['email_verified'] as bool? ?? false,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Conversion vers Map (pour Supabase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'nom': nom,
      'prenom': prenom,
      'niveau_code': niveauCode,
      'serie_code': serieCode,
      'telephone': telephone,
      'date_naissance': dateNaissance?.toIso8601String().split('T').first,
      'email_verified': emailVerified,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Conversion vers Map pour insertion (sans uid, created_at, updated_at)
  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map.remove('created_at');
    map.remove('updated_at');
    return map;
  }

  /// Copie avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? nom,
    String? prenom,
    String? niveauCode,
    String? serieCode,
    String? telephone,
    DateTime? dateNaissance,
    bool? emailVerified,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      niveauCode: niveauCode ?? this.niveauCode,
      serieCode: serieCode ?? this.serieCode,
      telephone: telephone ?? this.telephone,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      emailVerified: emailVerified ?? this.emailVerified,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    role,
    nom,
    prenom,
    niveauCode,
    serieCode,
    telephone,
    dateNaissance,
    emailVerified,
    actif,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: $role, nomComplet: $nomComplet)';
  }
}