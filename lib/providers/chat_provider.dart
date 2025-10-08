
import 'dart:async';

import 'package:easybosh_v2/core/config/app_config.dart';
import 'package:easybosh_v2/core/config/env.dart';
import 'package:easybosh_v2/main.dart';
import 'package:easybosh_v2/models/conversation_model.dart';
import 'package:easybosh_v2/models/message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../core/providers/auth_provider.dart';
import '../models/user_model.dart';

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
  late final SupabaseClient _client;
  late final GenerativeModel _model;
  String? _userId;

  @override
  ChatState build() {
    _client = ref.watch(supabaseClientProvider);
    final authState = ref.watch(authProvider);
    if (authState is AuthAuthenticated) {
      _userId = authState.user.uid;
    } else {
      _userId = null;
    }
    
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: Env.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1000,
        ),
      );
      print('Modèle Gemini initialisé avec succès');
    } catch (e) {
      print("ERREUR: Échec de l'initialisation de l'API Gemini: $e");
      // En cas d'échec, on initialise quand même le modèle avec une clé vide
      // pour éviter les erreurs, mais on ne pourra pas appeler l'API
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: 'dummy-key',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1000,
        ),
      );
    }
    
    return ChatState();
  }

  Future<void> deleteConversation(String conversationId) async {
    if (_userId == null) return;
    try {
      await _client.from('conversations').delete().eq('id', conversationId);
      final newConversations = state.conversations.where((c) => c.id != conversationId).toList();
      state = state.copyWith(conversations: newConversations);
      if (state.activeConversationId == conversationId) {
        state = state.copyWith(messages: [], clearActiveConversation: true);
      }
    } catch (e) {
      print("Erreur lors de la suppression de la conversation: $e");
    }
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
    print('sendMessage called with conversationId: $conversationId, content: $content');
    if (_userId == null) {
      print('Error: User ID is null');
      return;
    }
    
    try {
      // Mettre à jour l'état pour indiquer le chargement
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Créer un nouveau message utilisateur
      final userMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        content: content,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      );

      print('Created user message: ${userMessage.id} - ${userMessage.content}');

      // Mettre à jour l'état avec le message de l'utilisateur
      state = state.copyWith(
        messages: [...state.messages, userMessage],
      );

      print('State updated with user message. Messages count: ${state.messages.length}');

      try {
        String responseText;
        
        // Vérifier si la clé API est valide
        if (Env.geminiApiKey.isEmpty || Env.geminiApiKey == 'dummy-key') {
          // Réponse factice pour le débogage
          responseText = "Bonjour ! Je suis votre assistant virtuel. Pour le moment, je suis en mode démo. "
                       "Pour activer les réponses intelligentes, veuillez configurer une clé API Gemini valide.";
          print('Mode démo: Utilisation d\'une réponse factice');
        } else {
          print('Envoi du message à Gemini...');
          // Envoyer le message et obtenir la réponse
          final response = await _model.generateContent([Content.text(content)]);
          responseText = response.text ?? 'Désolé, je n\'ai pas pu générer de réponse.';
          
          print('Réponse reçue de Gemini: ${responseText.substring(0, responseText.length > 50 ? 50 : responseText.length)}...');
        }

        // Créer le message de l'assistant
        final assistantMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: conversationId,
          content: responseText,
          role: MessageRole.model,
          createdAt: DateTime.now(),
        );

        print('Created assistant message: ${assistantMessage.id}');

        // Mettre à jour l'état avec la réponse de l'assistant
        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isLoading: false,
        );

        print('State updated with assistant message. Messages count: ${state.messages.length}');
      } catch (e) {
        print('Error generating response: $e');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Erreur lors de la génération de la réponse: $e',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors de l\'envoi du message: $e',
      );
    }
  }

  Future<void> createConversation(String title, String firstMessage) async {
    if (_userId == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final conversationResponse = await _client
          .from('conversations')
          .insert({'user_id': _userId, 'title': title})
          .select()
          .single();
          
      final newConversation = ConversationModel.fromMap(conversationResponse);
      state = state.copyWith(
        conversations: [newConversation, ...state.conversations],
        activeConversationId: newConversation.id,
      );
      
      await sendMessage(newConversation.id, firstMessage);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erreur lors de la création de la conversation: $e',
        isLoading: false,
      );
    }
  }
}
