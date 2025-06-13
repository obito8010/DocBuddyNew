import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adds a single chat message to Firestore under the current user's document.
  Future<void> addChatMessage(String sender, String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in. Cannot save chat.");
      return;
    }

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('chat_history')
          .add({
        'sender': sender,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Message saved to Firestore");
    } catch (e) {
      print("Failed to save message: $e");
    }
  }

  /// Retrieves the chat history for the current user from Firestore.
  Future<List<Map<String, String>>> getChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in. Cannot fetch chat history.");
      return [];
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('chat_history')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'sender': data['sender']?.toString() ?? '',
          'text': data['message']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      print("Failed to fetch chat history: $e");
      return [];
    }
  }
}
