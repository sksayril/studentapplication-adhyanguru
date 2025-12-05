import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/api_service.dart';

class DoubtSolverScreen extends StatefulWidget {
  const DoubtSolverScreen({Key? key}) : super(key: key);

  @override
  State<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends State<DoubtSolverScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    // Add user message to chat
    final userMessage = ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Prepare messages for API (include conversation history)
      final apiMessages = _messages.map((m) => <String, String>{
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      // Call AI API
      final response = await ApiService.sendAIChatMessage(apiMessages);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success'] == true) {
            final aiMessage = ChatMessage(
              text: response['completion'] as String? ?? 'No response',
              isUser: false,
              timestamp: DateTime.now(),
            );
            _messages.add(aiMessage);
          } else {
            // Show error message
            final errorMessage = ChatMessage(
              text: response['message'] as String? ?? 'Failed to get response. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            );
            _messages.add(errorMessage);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final errorMessage = ChatMessage(
            text: 'Network error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          );
          _messages.add(errorMessage);
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF9F43),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.question_answer,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doubt Solver',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Powered',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Loading indicator
                        return _buildLoadingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          // Input area
          _buildInputArea(),
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9F43).withOpacity(0.2),
                  const Color(0xFFFF9F43).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_answer_outlined,
              size: 60,
              color: Color(0xFFFF9F43),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask Your Doubts',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Get instant answers to your questions. Type your doubt below and let AI help you!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F43).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: Color(0xFFFF9F43),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF9F43)
                    : isError
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isError
                    ? Border.all(color: Colors.red.shade300, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser
                          ? Colors.white
                          : isError
                              ? Colors.red.shade700
                              : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F43).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFFFF9F43),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F43).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 20,
              color: Color(0xFFFF9F43),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFFF9F43),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your doubt here...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyMedium,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F43),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool? isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError,
  });
}

