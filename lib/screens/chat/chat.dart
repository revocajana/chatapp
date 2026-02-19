import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      _messageController.clear();
      await _chatService.sendMessage(
        recipientId: widget.recipientId,
        text: text,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markMessagesAsRead(List<MessageModel> messages) {
    for (final message in messages) {
      if (message.recipientId == _auth.currentUser?.uid && !message.read) {
        _chatService.markAsRead(message.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientName)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.06),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _chatService.getMessages(widget.recipientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (!_isFirstLoad &&
                            messages.length > _previousMessageCount) {
                          final newMessages = messages
                              .skip(_previousMessageCount)
                              .toList();
                          for (final msg in newMessages) {
                            if (msg.senderId == widget.recipientId &&
                                msg.senderId != _auth.currentUser?.uid) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'New message from ${widget.recipientName}: ${msg.text}',
                                    ),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              });
                            }
                          }
                        }

                        _previousMessageCount = messages.length;
                        _isFirstLoad = false;

                        if (messages.isNotEmpty) {
                          _markMessagesAsRead(messages);
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet. Start the conversation!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });

                        final items = _buildCombinedMessageList(messages);
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            if (item is String) {
                              return _buildDateSeparator(
                                context: context,
                                dateTime: DateTime.parse(item),
                              );
                            }

                            final message = item as MessageModel;
                            final isCurrentUser =
                                message.senderId == _auth.currentUser?.uid;
                            return _buildMessageBubble(
                              context: context,
                              message: message,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required MessageModel message,
    required bool isCurrentUser,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? colorScheme.primary
                  : colorScheme.primaryContainer.withValues(alpha: 0.52),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCurrentUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
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
                              ? colorScheme.onPrimary.withValues(alpha: 0.72)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.read
                              ? colorScheme.tertiary
                              : colorScheme.onPrimary.withValues(alpha: 0.72),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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

      if (lastDate == null || lastDate != messageDate) {
        combined.add(messageDate.toString());
        lastDate = messageDate;
      }

      combined.add(message);
    }

    return combined;
  }

  Widget _buildDateSeparator({
    required BuildContext context,
    required DateTime dateTime,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
