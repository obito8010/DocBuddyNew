import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Create a new chat session
  Future<String?> createNewChatSession({String? title}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .add({
        'title': title ?? 'New Chat',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      print("❌ Failed to create chat: $e");
      return null;
    }
  }

  // ✅ List all chat sessions
  Future<List<Map<String, dynamic>>> getAllChatSessions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'chatId': doc.id,
          'title': doc['title'] ?? 'Chat',
          'createdAt': doc['createdAt'],
        };
      }).toList();
    } catch (e) {
      print("❌ Failed to fetch chats: $e");
      return [];
    }
  }

  // ✅ Add a message to a specific chat
  Future<void> addMessageToChat(
      String chatId, String sender, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender': sender,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Failed to add message: $e");
    }
  }

  // ✅ Get messages from a specific chat
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'sender': doc['sender'],
          'text': doc['message'],
          'timestamp': doc['timestamp'],
        };
      }).toList();
    } catch (e) {
      print("❌ Failed to fetch messages: $e");
      return [];
    }
  }

  // ✅ Delete a message from a specific chat
  Future<void> deleteMessage(String chatId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print("❌ Failed to delete message: $e");
    }
  }

  // ✅ Rename a chat session
  Future<void> renameChatSession(String chatId, String newTitle) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .update({'title': newTitle});
    } catch (e) {
      print("❌ Failed to rename chat: $e");
    }
  }

  // ✅ Delete a chat session and all its messages
  Future<void> deleteChatSession(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final chatRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId);

      final messagesSnapshot = await chatRef.collection('messages').get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await chatRef.delete();
    } catch (e) {
      print("❌ Failed to delete chat session: $e");
    }
  }
}
