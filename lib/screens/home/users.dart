import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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
    return StreamBuilder<List<UserModel>>(
      stream: _userService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary(context)),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          // Show debug info to help identify why users are missing
          final current = FirebaseAuth.instance.currentUser;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No other users found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey(context, 700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Current user: ${current?.uid ?? "(not signed in)"}',
                  style: TextStyle(color: AppColors.grey(context, 600)),
                ),
                Text(
                  'Email: ${current?.email ?? "-"}',
                  style: TextStyle(color: AppColors.grey(context, 600)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // Debug: show raw users collection snapshot
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
                              style: TextStyle(
                                color: AppColors.grey(context, 600),
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
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.white,
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

                  // Show a single-line preview of the last message
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
            );
          },
        );
      },
    );
  }
}
