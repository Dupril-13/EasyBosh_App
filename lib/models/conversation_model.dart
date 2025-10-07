
import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, createdAt, updatedAt];
}
