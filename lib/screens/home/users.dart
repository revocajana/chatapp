import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = userService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<UserModel>>(
      stream: _userService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          final current = FirebaseAuth.instance.currentUser;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 52,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 10),
                Text(
                  'No other users found',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Current user: ${current?.uid ?? "(not signed in)"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Email: ${current?.email ?? "-"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    if (snap.hasError) {
                      return Text(
                        'Error reading users collection: ${snap.error}',
                      );
                    }
                    final docs = snap.data?.docs ?? [];
                    return Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          return ListTile(
                            title: Text(d.id),
                            subtitle: Text(
                              d.data().toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                  foregroundColor: colorScheme.primary,
                  child: Text(
                    (user.displayName ?? user.email)
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                title: Text(user.displayName ?? 'User'),
                subtitle: StreamBuilder<MessageModel?>(
                  stream: chatService.lastMessageStream(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (snap.hasError) {
                      return Text('Error: ${snap.error}');
                    }

                    final last = snap.data;
                    if (last == null) {
                      return const Text('No messages yet');
                    }

                    final preview = last.text.replaceAll('\n', ' ');
                    return Text(
                      preview.length > 60
                          ? '${preview.substring(0, 57)}...'
                          : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        recipientId: user.uid,
                        recipientName: user.displayName ?? user.email,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
