import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
				SnackBar(content: Text('Error sending message: $e')),
			);
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
					icon: const Icon(Icons.arrow_back),
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
									return const Center(child: CircularProgressIndicator());
								}

								if (snapshot.hasError) {
									return Center(child: Text('Error: ${snapshot.error}'));
								}

								final messages = snapshot.data ?? [];

								if (messages.isEmpty) {
									return const Center(
										child: Text('No messages yet. Start the conversation!'),
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
									itemCount: messages.length,
									itemBuilder: (context, index) {
										final message = messages[index];
										final isCurrentUser = message.senderId == _auth.currentUser?.uid;

										return Align(
											alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
											child: Container(
												margin: const EdgeInsets.symmetric(vertical: 4),
												padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
												decoration: BoxDecoration(
													color: isCurrentUser
														? Theme.of(context).colorScheme.primary
														: Colors.grey[300],
													borderRadius: BorderRadius.circular(12),
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															message.text,
															style: TextStyle(
																color: isCurrentUser ? Colors.white : Colors.black,
														),
														),
														const SizedBox(height: 4),
														Text(
															_formatTime(message.timestamp),
															style: TextStyle(
																fontSize: 12,
																color: isCurrentUser ? Colors.white70 : Colors.grey[600],
															),
														),
													],
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
							color: Colors.white,
							border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
											contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
										),
										onSubmitted: (_) => _sendMessage(),
									),
								),
								const SizedBox(width: 8),
								FloatingActionButton(
									mini: true,
									onPressed: _sendMessage,
									child: const Icon(Icons.send),
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
}

