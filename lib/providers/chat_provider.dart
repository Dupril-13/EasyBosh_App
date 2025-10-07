
import 'dart:async';

import 'package:easybosh_v2/core/config/app_config.dart';
import 'package:easybosh_v2/main.dart';
import 'package:easybosh_v2/models/conversation_model.dart';
import 'package:easybosh_v2/models/message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../core/providers/auth_provider.dart';

part 'chat_provider.g.dart';

class ChatState {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? errorMessage;
  final String? activeConversationId;

  ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeConversationId,
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? activeConversationId,
    bool clearActiveConversation = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      activeConversationId: clearActiveConversation ? null : activeConversationId ?? this.activeConversationId,
    );
  }
}

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  late SupabaseClient _client;
  late GenerativeModel _model;
  String? _userId;

  @override
  ChatState build() {
    _client = ref.watch(supabaseClientProvider);
    final apiKey = AppConfig.geminiApiKey;

    if (apiKey.isEmpty) {
      print("ERREUR: Clé API Gemini non trouvée.");
    }
    
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

    final authState = ref.watch(authProvider);
    _userId = (authState is AuthAuthenticated) ? authState.user.uid : null;

    if (_userId != null) {
      Future(() => fetchConversations());
    }

    return ChatState();
  }

  Future<void> fetchConversations() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final response = await _client
          .from('conversations')
          .select()
          .eq('user_id', _userId!)
          .order('updated_at', ascending: false);

      final conversations = (response as List).map((data) => ConversationModel.fromMap(data)).toList();
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    if (conversationId.isEmpty) {
      state = state.copyWith(messages: [], activeConversationId: null, clearActiveConversation: true);
      return;
    }
    state = state.copyWith(isLoading: true, activeConversationId: conversationId, messages: []);
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (response as List).map((data) => MessageModel.fromMap(data)).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);

    try {
      // 1. Sauvegarder le message de l'utilisateur
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'content': content,
        'role': 'user',
        'user_id': _userId,
      });

      // 2. Récupérer l'historique complet de la conversation
      final historyResponse = await _client
          .from('messages')
          .select('role, content')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      
      final history = (historyResponse as List).map((messageData) {
          final role = messageData['role'] as String;
          final text = messageData['content'] as String;
          return Content(role, [TextPart(text)]);
      }).toList();

      // 3. Appeler Gemini avec l'historique
      final chatSession = _model.startChat(history: history);
      final response = await chatSession.sendMessage(Content.text(content));
      final modelContent = response.text;

      // 4. Sauvegarder la réponse du modèle
      if (modelContent != null) {
        await _client.from('messages').insert({
          'conversation_id': conversationId,
          'content': modelContent,
          'role': 'model',
          'user_id': _userId,
        });
      }

      // 5. Rafraîchir la liste des messages pour afficher les deux nouveaux messages
      await fetchMessages(conversationId);

    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    } finally {
        if(state.isLoading) {
            state = state.copyWith(isLoading: false);
        }
    }
  }

  Future<void> createConversation(String title, String firstMessage) async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final conversationResponse = await _client.from('conversations').insert({
        'user_id': _userId,
        'title': title,
      }).select().single();

      final newConversation = ConversationModel.fromMap(conversationResponse);
      state = state.copyWith(conversations: [newConversation, ...state.conversations], activeConversationId: newConversation.id);
      
      await sendMessage(newConversation.id, firstMessage);

    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }
}
