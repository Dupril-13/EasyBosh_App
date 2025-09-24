import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Import pour le formatage de date

// Modèle simple pour un message de chat
class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });
}

// Modèle simple pour une conversation (pour le Drawer)
class Conversation {
  final String id;
  String title; // Peut être modifié si la conversation est renommée
  DateTime lastActivity;
  String lastMessageSnippet; // Pour afficher un aperçu

  Conversation({
    required this.id,
    required this.title,
    required this.lastActivity,
    this.lastMessageSnippet = "Aucun message récent",
  });
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _currentMessages = [
    ChatMessage(
        text:
        'Bonjour ! Je suis EasyBot. Comment puis-je vous aider aujourd\'hui ?',
        isUserMessage: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
    ChatMessage(
        text: 'J\'aimerais des informations sur les quiz de mathématiques.',
        isUserMessage: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
    ChatMessage(
        text:
        'Bien sûr ! Nous avons des quiz d\'algèbre, de géométrie et d\'analyse. Souhaitez-vous que je vous montre la liste ?',
        isUserMessage: false,
        timestamp: DateTime.now()),
  ];

  final List<Conversation> _conversations = [
    Conversation(
        id: '1',
        title: 'Quiz de Mathématiques',
        lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
        lastMessageSnippet: "Ok, quels types de quiz sont dispo ?"),
    Conversation(
        id: '2',
        title: 'Aide sur les épreuves de Physique Mécanique et Ondes Progressives',
        lastActivity: DateTime.now().subtract(const Duration(days: 1)),
        lastMessageSnippet: "Merci beaucoup pour votre aide !"),
    Conversation(
        id: '3',
        title: 'Discussion Générale',
        lastActivity: DateTime.now().subtract(const Duration(days: 3)),
        lastMessageSnippet: "C'est noté."),
  ];

  String _activeConversationId = '0';
  String _currentChatTitle = "EasyBot";

  @override
  void initState() {
    super.initState();
    if (_conversations.isNotEmpty) {
      _currentChatTitle = "EasyBot"; // Titre par défaut
    } else {
      _startNewConversation(initialLoad: true);
    }
  }

  void _updateConversationActivity(String conversationId, String lastMessage) {
    try {
      final conversation =
      _conversations.firstWhere((conv) => conv.id == conversationId);
      conversation.lastActivity = DateTime.now();
      conversation.lastMessageSnippet = lastMessage.length > 30
          ? '${lastMessage.substring(0, 30)}...'
          : lastMessage;
      _conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    } catch (e) {
      // Conversation non trouvée
    }
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    if (text.trim().isEmpty) return;

    final userMessage =
    ChatMessage(text: text, isUserMessage: true, timestamp: DateTime.now());
    setState(() {
      _currentMessages.add(userMessage);
      if (_activeConversationId != '0') {
        _updateConversationActivity(_activeConversationId, text);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      final botResponseText =
          'Je traite votre demande : "$text". Actuellement, je suis en phase de développement pour répondre plus précisément !';
      final botMessage = ChatMessage(
          text: botResponseText,
          isUserMessage: false,
          timestamp: DateTime.now());
      setState(() {
        _currentMessages.add(botMessage);
        if (_activeConversationId != '0') {
          _updateConversationActivity(_activeConversationId, botResponseText);
        }
        _scrollToBottom();
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadConversation(Conversation conversation, {bool initialLoad = false}) {
    if (!initialLoad && Navigator.canPop(context)) Navigator.of(context).pop();
    setState(() {
      _activeConversationId = conversation.id;
      _currentChatTitle = conversation.title;
      _currentMessages = [
        ChatMessage(
            text: 'Conversation "${conversation.title}" chargée.',
            isUserMessage: false,
            timestamp: DateTime.now()),
        ChatMessage(
            text: conversation.lastMessageSnippet,
            isUserMessage: false,
            timestamp: DateTime.now().add(const Duration(seconds: 1))),
      ];
      _updateConversationActivity(conversation.id, _currentMessages.last.text);
      _scrollToBottom();
    });
    // SnackBar supprimé ici
  }

  Future<void> _showDeleteConfirmationDialog(Conversation conversation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text("Voulez-vous vraiment supprimer la conversation \"${conversation.title}\" ?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _conversations.removeWhere((conv) => conv.id == conversation.id);
        if (_activeConversationId == conversation.id) {
          if (_conversations.isNotEmpty) {
            _loadConversation(_conversations.first, initialLoad: true);
          } else {
            _startNewConversation(initialLoad: true);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Conversation "${conversation.title}" supprimée'),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  void _startNewConversation({bool initialLoad = false}) {
    if (!initialLoad && Navigator.canPop(context)) Navigator.of(context).pop();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newConversation = Conversation(
        id: newId,
        title: "Nouvelle Conversation - ${DateFormat('dd/MM HH:mm').format(DateTime.now())}",
        lastActivity: DateTime.now(),
        lastMessageSnippet: "Comment puis-je vous aider ?");
    setState(() {
      _activeConversationId = newId;
      _currentChatTitle = newConversation.title;
      _currentMessages = [
        ChatMessage(
            text: 'Nouvelle conversation. Comment puis-je vous aider ?',
            isUserMessage: false,
            timestamp: DateTime.now()),
      ];
      _conversations.insert(0, newConversation);
      _updateConversationActivity(newId, _currentMessages.first.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final Color darkDividerColor = Theme.of(context).primaryColor; // Plus utilisé

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 1.0,
        title: Text(
          _currentChatTitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white, size: 26),
          tooltip: 'Historique des conversations',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
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
      drawer: Drawer(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Coins moins arrondis
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Padding inférieur ajusté pour espacement
              child: const Center(
                child: Text(
                  'Historique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            // AUCUN Divider ici
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              leading: Icon(Icons.add_comment_outlined,
                  color: Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor, size: 24),
              title: const Text(
                'Nouvelle conversation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onTap: _startNewConversation,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    leading: const Icon(Icons.chat_outlined,
                        size: 22, color: Colors.black54),
                    title: Text(
                      conversation.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${conversation.lastMessageSnippet} - ${DateFormat('dd/MM, HH:mm').format(conversation.lastActivity)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 22),
                      tooltip: 'Supprimer la conversation',
                      onPressed: () => _showDeleteConfirmationDialog(conversation),
                    ),
                    onTap: () => _loadConversation(conversation),
                    selected: _activeConversationId == conversation.id,
                    selectedTileColor: Colors.grey[200],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8.0)
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              itemCount: _currentMessages.length,
              itemBuilder: (context, index) {
                final message = _currentMessages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUserMessage;
    final alignment =
    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
    isUser ? Theme.of(context).primaryColor.withOpacity(0.9) : Colors.white;
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
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ]),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15.5, height: 1.3),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
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
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            color: Colors.grey.withOpacity(0.1),
          ),
        ],
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
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
