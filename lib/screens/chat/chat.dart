import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // run 'flutter pub add intl' to add this package and then 'flutter pub get' to install it
import '../../models/message_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = chatService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ScrollController _scrollController;
  int _previousMessageCount = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      _messageController.clear();
      await _chatService.sendMessage(
        recipientId: widget.recipientId,
        text: text,
      );
      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _markMessagesAsRead(List<MessageModel> messages) {
    for (var message in messages) {
      if (message.recipientId == _auth.currentUser?.uid && !message.read) {
        _chatService.markAsRead(message.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages display
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.recipientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                // Show notification when new message arrives from the other user
                if (!_isFirstLoad && messages.length > _previousMessageCount) {
                  final newMessages = messages
                      .skip(_previousMessageCount)
                      .toList();
                  for (var msg in newMessages) {
                    if (msg.senderId == widget.recipientId &&
                        msg.senderId != _auth.currentUser?.uid) {
                      // Schedule snack bar to be shown after the current build frame.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'New message from ${widget.recipientName}: ${msg.text}',
                            ),
                            duration: const Duration(seconds: 3),
                            backgroundColor: AppColors.primary(context),
                          ),
                        );
                      });
                    }
                  }
                }

                _previousMessageCount = messages.length;
                _isFirstLoad = false;

                // Mark messages as read when they appear
                if (messages.isNotEmpty) {
                  _markMessagesAsRead(messages);
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: AppColors.grey(context, 600)),
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _buildCombinedMessageList(messages).length,
                  itemBuilder: (context, index) {
                    final item = _buildCombinedMessageList(messages)[index];

                    if (item is String) {
                      // It's a date separator string
                      return _buildDateSeparator(DateTime.parse(item));
                    }

                    // It's a MessageModel
                    final message = item as MessageModel;
                    final isCurrentUser =
                        message.senderId == _auth.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.grey(context, 300),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(
                                isCurrentUser ? 18 : 4,
                              ),
                              bottomRight: Radius.circular(
                                isCurrentUser ? 4 : 18,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackWithOpacity(0.1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? AppColors.white
                                      : AppColors.black87(),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCurrentUser
                                          ? AppColors.white.withOpacity(0.7)
                                          : AppColors.grey(context, 600),
                                    ),
                                  ),
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.read
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: message.read
                                          ? AppColors.blue300()
                                          : AppColors.white.withOpacity(0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input field
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.grey(context, 300)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.primary(context),
                  onPressed: _sendMessage,
                  child: Icon(Icons.send, color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Build a combined list of messages and date separators
  List<dynamic> _buildCombinedMessageList(List<MessageModel> messages) {
    if (messages.isEmpty) return [];

    final combined = <dynamic>[];
    DateTime? lastDate;

    for (final message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      // Add date separator if date changed
      if (lastDate == null || lastDate != messageDate) {
        combined.add(
          messageDate.toString(),
        ); // Store date as string for separator
        lastDate = messageDate;
      }

      combined.add(message);
    }

    return combined;
  }

  Widget _buildDateSeparator(DateTime dateTime) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    String dateLabel;
    if (dateOnly == todayOnly) {
      dateLabel = 'Today';
    } else if (dateOnly == yesterdayOnly) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('MMM d, yyyy').format(dateTime);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey(context, 300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: AppColors.grey(context, 700),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
