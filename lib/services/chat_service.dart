import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a message
  Future<void> sendMessage({
    required String recipientId,
    required String text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final message = MessageModel(
        id: '',
        senderId: currentUser.uid,
        recipientId: recipientId,
        text: text.trim(),
        timestamp: DateTime.now(),
        read: false,
      );

      await _firestore.collection('messages').add(message.toMap());
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get stream of messages between current user and another user
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Query all messages and filter client-side for real-time updates
    return _firestore
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .where((msg) =>
                  (msg.senderId == currentUserId && msg.recipientId == otherUserId) ||
                  (msg.senderId == otherUserId && msg.recipientId == currentUserId))
              .toList();

          // Sort by timestamp ascending (oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  /// Mark messages as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({'read': true});
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }
}

final chatService = ChatService();
