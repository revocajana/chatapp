import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
	final String recipientId;
	final String recipientName;

	const ChatScreen({
		super.key,
		required this.recipientId,
		required this.recipientName,
	});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text(recipientName)),
			body: const Center(child: Text('Chat screen (minimal)')),
		);
	}
}

