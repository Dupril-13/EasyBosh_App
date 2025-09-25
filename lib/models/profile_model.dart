import 'package:equatable/equatable.dart';

// Représente les données de la table public.profiles
class ProfileModel extends Equatable {
  final String id; // Correspond à auth.users.id ET profiles.id
  final String? firstName;
  final String? lastName;
  final String? fullName; // Peut être directement rempli depuis la BD
  final String? avatarUrl; // Peut être une URL vers Supabase Storage
  final UserRole role;
  final String? studentLevelCode;
  final String? studentSerieCode;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? teacherSpecialty;
  final String? bio;
  final String? websiteUrl;
  final bool isActive;
  final DateTime? updatedAt; // Date de mise à jour du profil

  const ProfileModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.avatarUrl,
    required this.role,
    this.studentLevelCode,
    this.studentSerieCode,
    this.phoneNumber,
    this.dateOfBirth,
    this.teacherSpecialty,
    this.bio,
    this.websiteUrl,
    this.isActive = true,
    this.updatedAt,
  });

  // Getters utiles
  String get displayFullName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return 'Utilisateur'; // Fallback
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty) {
      return '${firstName!.substring(0, 1)}${lastName!.substring(0, 1)}'.toUpperCase();
    } else if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length > 1) {
        return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
      } else if (parts.first.isNotEmpty) {
         return parts.first.substring(0, 1).toUpperCase();
      }
    }
    return '?'; // Fallback
  }

  bool get isStudent => role == UserRole.student;
  bool get isTeacher => role == UserRole.teacher;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => isTeacher || isAdmin;

  bool get isStudentProfileComplete {
    if (isStudent) {
      return firstName != null && firstName!.isNotEmpty &&
          lastName != null && lastName!.isNotEmpty &&
          studentLevelCode != null && studentLevelCode!.isNotEmpty &&
          // Pour la 3ème, studentSerieCode peut être null
          ( (studentLevelCode == '3eme') || (studentSerieCode != null && studentSerieCode!.isNotEmpty) );
    }
    // Pour les autres rôles, on pourrait avoir d'autres critères
    return firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: UserRoleHelper.fromString(map['role'] as String? ?? 'student'),
      studentLevelCode: map['student_level_code'] as String?,
      studentSerieCode: map['student_serie_code'] as String?,
      phoneNumber: map['phone_number'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'] as String)
          : null,
      teacherSpecialty: map['teacher_specialty'] as String?,
      bio: map['bio'] as String?,
      websiteUrl: map['website_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    // Le full_name est souvent construit en BD ou via getter, ne pas l'envoyer directement sauf si intentionnel
    // if (fullName != null) map['full_name'] = fullName; 
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (studentLevelCode != null) map['student_level_code'] = studentLevelCode;
    if (studentSerieCode != null) map['student_serie_code'] = studentSerieCode; else map['student_serie_code'] = null;
    if (phoneNumber != null) map['phone_number'] = phoneNumber;
    if (dateOfBirth != null) map['date_of_birth'] = dateOfBirth!.toIso8601String().split('T').first;
    if (teacherSpecialty != null) map['teacher_specialty'] = teacherSpecialty;
    if (bio != null) map['bio'] = bio;
    if (websiteUrl != null) map['website_url'] = websiteUrl;
    map['is_active'] = isActive;
    // 'updated_at' sera géré par le trigger moddatetime dans la base de données
    return map;
  }
  
  Map<String, dynamic> toInsertMap() {
    return {
      'id': id, 
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName ?? (firstName != null && lastName != null ? '$firstName $lastName' : null),
      'avatar_url': avatarUrl,
      'role': UserRoleHelper.asString(role),
      'student_level_code': studentLevelCode,
      'student_serie_code': studentSerieCode,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'teacher_specialty': teacherSpecialty,
      'bio': bio,
      'website_url': websiteUrl,
      'is_active': isActive,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    String? studentLevelCode,
    String? studentSerieCode,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? teacherSpecialty,
    String? bio,
    String? websiteUrl,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      studentLevelCode: studentLevelCode ?? this.studentLevelCode,
      studentSerieCode: studentSerieCode ?? this.studentSerieCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      teacherSpecialty: teacherSpecialty ?? this.teacherSpecialty,
      bio: bio ?? this.bio,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        fullName,
        avatarUrl,
        role,
        studentLevelCode,
        studentSerieCode,
        phoneNumber,
        dateOfBirth,
        teacherSpecialty,
        bio,
        websiteUrl,
        isActive,
        updatedAt
      ];

  @override
  String toString() {
    return 'ProfileModel(id: $id, name: $displayFullName, role: $role)';
  }
}

// Enum pour les rôles (plus sûr que des strings)
enum UserRole { student, teacher, admin, unknown }

class UserRoleHelper {
  static String asString(UserRole role) {
    switch (role) {
      case UserRole.student: return 'student';
      case UserRole.teacher: return 'teacher';
      case UserRole.admin: return 'admin';
      default: return 'unknown';
    }
  }

  static UserRole fromString(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'student': return UserRole.student;
      case 'teacher': return UserRole.teacher;
      case 'admin': return UserRole.admin;
      default: return UserRole.unknown;
    }
  }
}
