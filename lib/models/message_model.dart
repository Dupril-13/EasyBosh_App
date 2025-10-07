
import 'package:equatable/equatable.dart';

enum MessageRole { user, model }

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      content: map['content'] as String,
      role: (map['role'] as String) == 'user' ? MessageRole.user : MessageRole.model,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'content': content,
      'role': role == MessageRole.user ? 'user' : 'model',
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, conversationId, content, role, createdAt];
}
