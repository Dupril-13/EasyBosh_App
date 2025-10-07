
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final chatNotifier = ref.read(chatProvider.notifier);
    final activeConversationId = ref.read(chatProvider).activeConversationId;

    if (activeConversationId != null) {
      chatNotifier.sendMessage(activeConversationId, text.trim());
    } else {
      // Crée un titre court pour la nouvelle conversation
      final title = text.trim().length > 30 ? "${text.trim().substring(0, 30)}..." : text.trim();
      chatNotifier.createConversation(title, text.trim());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    ref.listen(chatProvider.select((value) => value.messages.length), (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    String currentTitle = "EasyBot";
    if (chatState.activeConversationId != null) {
      try {
        final activeConversation = chatState.conversations.firstWhere((c) => c.id == chatState.activeConversationId);
        currentTitle = activeConversation.title;
      } catch (e) {
        currentTitle = "Conversation...";
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 1.0,
        title: Text(
          currentTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.message_search, color: Colors.white, size: 26),
          tooltip: 'Historique des conversations',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            tooltip: 'Retour',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/cours');
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: Column(
        children: [
          if (chatState.isLoading && chatState.messages.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (chatState.messages.isEmpty)
             Expanded(child: _buildWelcomeMessage())
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0), // +1 for loading indicator
                itemBuilder: (context, index) {
                  if (chatState.isLoading && index == chatState.messages.length) {
                    return _buildTypingIndicator();
                  }
                  final message = chatState.messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.message_question, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'Bonjour !', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Je suis EasyBot, votre assistant pédagogique. Posez-moi une question pour commencer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 100),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
          ),
          child: const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)), // Placeholder for a real typing indicator
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20))),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Center(
              child: Text('Historique', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            leading: Icon(Iconsax.add_square, color: Theme.of(context).primaryColor, size: 24),
            title: const Text('Nouvelle conversation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            onTap: () {
              chatNotifier.fetchMessages(''); // Clear current conversation
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Expanded(
            child: chatState.isLoading && chatState.conversations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    itemCount: chatState.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = chatState.conversations[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                        leading: const Icon(Iconsax.message_2, size: 22, color: Colors.black54),
                        title: Text(conversation.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(DateFormat('dd/MM, HH:mm').format(conversation.updatedAt), style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          chatNotifier.fetchMessages(conversation.id);
                          Navigator.of(context).pop();
                        },
                        selected: chatState.activeConversationId == conversation.id,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final bool isUser = message.role == MessageRole.user;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? Theme.of(context).primaryColor : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))]),
            child: Text(message.content, style: TextStyle(color: textColor, fontSize: 15.5, height: 1.3)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(DateFormat('HH:mm').format(message.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(offset: const Offset(0, -2), blurRadius: 5, color: Colors.grey.withOpacity(0.1))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message à EasyBot...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
