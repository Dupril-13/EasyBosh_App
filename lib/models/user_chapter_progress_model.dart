import 'package:equatable/equatable.dart';

class UserChapterProgressModel extends Equatable {
  final String id;
  final String userId;
  final int chapitreId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserChapterProgressModel({
    required this.id,
    required this.userId,
    required this.chapitreId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserChapterProgressModel.fromJson(Map<String, dynamic> json) {
    return UserChapterProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chapitreId: json['chapitre_id'] as int,
      isCompleted: json['is_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'chapitre_id': chapitreId,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserChapterProgressModel copyWith({
    String? id,
    String? userId,
    int? chapitreId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserChapterProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chapitreId: chapitreId ?? this.chapitreId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, chapitreId, isCompleted, createdAt, updatedAt];
}
