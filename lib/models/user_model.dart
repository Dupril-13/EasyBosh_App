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
    if (prenom != null && nom != null && prenom!.isNotEmpty && nom!.isNotEmpty) {
      return '$prenom $nom';
    } else if (prenom != null && prenom!.isNotEmpty) {
      return prenom!;
    } else if (nom != null && nom!.isNotEmpty) {
      return nom!;
    }
    return email.split('@').first;
  }

  String get initiales {
    if (prenom != null && prenom!.isNotEmpty && nom != null && nom!.isNotEmpty) {
      return '${prenom!.substring(0, 1)}${nom!.substring(0, 1)}'.toUpperCase();
    } else if (prenom != null && prenom!.isNotEmpty) {
      return prenom!.substring(0, 1).toUpperCase();
    } else if (nom != null && nom!.isNotEmpty) {
      return nom!.substring(0, 1).toUpperCase();
    }    
    return email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'U';
  }

  bool get isEtudiant => role == 'etudiant';
  bool get isEnseignant => role == 'enseignant';
  bool get isAdmin => role == 'admin';
  bool get isStaff => isEnseignant || isAdmin;

  /// Vérification de profil complet pour les étudiants
  bool get isProfileComplete {
    if (isEtudiant) {
      bool hasNiveau = niveauCode != null && niveauCode!.isNotEmpty;
      // Pour 3eme, serieCode peut être vide ou null
      bool hasSerie = niveauCode == '3eme' || (serieCode != null && serieCode!.isNotEmpty);
      return nom != null && nom!.isNotEmpty &&
          prenom != null && prenom!.isNotEmpty &&
          hasNiveau &&
          hasSerie;
    }
    return nom != null && nom!.isNotEmpty && prenom != null && prenom!.isNotEmpty;
  }

  /// Factory depuis Map (pour Supabase)
  factory UserModel.fromMap(Map<String, dynamic> map, {required String emailFromSession, required bool emailVerifiedFromSession}) {
    return UserModel(
      uid: map['id'] as String, // Clé de 'profiles'
      email: emailFromSession,    // Fourni depuis la session
      role: map['role'] as String? ?? 'student', 
      nom: map['last_name'] as String?,
      prenom: map['first_name'] as String?,
      niveauCode: map['student_level_code'] as String?,
      serieCode: map['student_serie_code'] as String?,
      telephone: map['phone_number'] as String?,
      dateNaissance: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'] as String)
          : null,
      emailVerified: emailVerifiedFromSession,
      actif: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : (map['updated_at'] != null 
              ? DateTime.parse(map['updated_at'] as String) 
              : DateTime.now()), // Fallback si created_at et updated_at sont nulls
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : DateTime.now(), // Fallback pour updatedAt
    );
  }

  Map<String, dynamic> toMapForProfiles() { 
    return {
      'id': uid,
      'role': role,
      'last_name': nom,
      'first_name': prenom,
      'full_name': (prenom != null && nom != null && prenom!.isNotEmpty && nom!.isNotEmpty) ? '$prenom $nom' : null,
      'student_level_code': niveauCode,
      'student_serie_code': serieCode,
      'phone_number': telephone,
      'date_of_birth': dateNaissance?.toIso8601String().split('T').first,
      'is_active': actif,
      'updated_at': updatedAt.toIso8601String(),
      // created_at est géré par la DB ou n'est pas mis à jour par le client
    };
  }

  /// Conversion vers Map (pour Supabase - utilisé par AuthNotifier lors de l'inscription)
  Map<String, dynamic> toMap() {
    return {
      // Cette map doit correspondre aux attentes de AuthNotifier pour l'insertion
      // Elle devrait idéalement utiliser les noms de colonnes de la table 'profiles'
      'id': uid, 
      'role': role,
      'last_name': nom,
      'first_name': prenom,
      // 'full_name' est souvent calculé ou géré par la DB, ou construit comme ci-dessus
      'student_level_code': niveauCode,
      'student_serie_code': serieCode,
      'phone_number': telephone,
      'date_of_birth': dateNaissance?.toIso8601String().split('T').first,
      'is_active': actif,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(), // Inclus pour la cohérence si nécessaire ailleurs
      // L'email et email_verified ne sont généralement pas stockés directement dans cette table `profiles` si elle est séparée de auth.users
    };
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
    return 'UserModel(uid: $uid, email: $email, role: $role, nomComplet: $nomComplet, niveau: $niveauCode, serie: $serieCode)';
  }
}
