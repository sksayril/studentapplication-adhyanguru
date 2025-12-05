import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../services/chat_database.dart';
import '../../services/api_service.dart';
import 'chat_history_screen.dart';

class AIChatScreen extends StatefulWidget {
  final int? chatSessionId;

  const AIChatScreen({Key? key, this.chatSessionId}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatDatabase _db = ChatDatabase.instance;
  
  int? _currentSessionId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  String? _sessionTitle;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.chatSessionId != null) {
      // Load existing chat
      await _loadChatSession(widget.chatSessionId!);
    } else {
      // Create new chat
      await _createNewChat();
    }
  }

  Future<void> _createNewChat() async {
    final sessionId = await _db.createChatSession('New Chat');
    setState(() {
      _currentSessionId = sessionId;
      _sessionTitle = 'New Chat';
      _messages = [];
      _isLoadingHistory = false;
    });
  }

  Future<void> _loadChatSession(int sessionId) async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final session = await _db.getChatSession(sessionId);
      final messages = await _db.getMessages(sessionId);

      setState(() {
        _currentSessionId = sessionId;
        _sessionTitle = session?['title'] as String? ?? 'Chat';
        _messages = messages;
        _isLoadingHistory = false;
      });

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentSessionId == null) return;

    // Add user message to UI
    final userMessage = {
      'role': 'user',
      'content': messageText,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    // Save user message to database
    await _db.addMessage(_currentSessionId!, 'user', messageText);

    // Update chat title if this is the first message
    if (_messages.length == 1 && _sessionTitle == 'New Chat') {
      final newTitle = messageText.length > 30 
          ? '${messageText.substring(0, 30)}...' 
          : messageText;
      await _db.updateChatSessionTitle(_currentSessionId!, newTitle);
      setState(() {
        _sessionTitle = newTitle;
      });
    }

    // Prepare messages for API (include conversation history)
    final apiMessages = _messages.map((msg) => {
      'role': msg['role'] as String,
      'content': msg['content'] as String,
    }).toList();

    // Call AI API
    final response = await ApiService.sendAIChatMessage(apiMessages);

    if (mounted) {
      if (response['success'] == true) {
        final aiResponse = response['completion'] as String;
        
        // Add AI message to UI
        final aiMessage = {
          'role': 'assistant',
          'content': aiResponse,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        
        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });

        // Save AI message to database
        await _db.addMessage(_currentSessionId!, 'assistant', aiResponse);
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to get AI response'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      _scrollToBottom();
    }
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sessionTitle ?? 'AI Chat',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
              if (result == true && _currentSessionId != null) {
                _loadChatSession(_currentSessionId!);
              }
            },
          ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask Finoma anything! I\'m here to help you learn.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Finoma',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        h1: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        h3: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        strong: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        em: TextStyle(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        listBullet: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                        blockquote: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        blockquotePadding: const EdgeInsets.all(12),
                      ),
                      shrinkWrap: true,
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Finoma',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finoma',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _TypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Typing dots animation widget
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _animations[index].value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

