import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateUsernameScreen extends StatefulWidget {
  const UpdateUsernameScreen({super.key});

  @override
  State<UpdateUsernameScreen> createState() => _UpdateUsernameScreenState();
}

class _UpdateUsernameScreenState extends State<UpdateUsernameScreen> {
  final TextEditingController usernameController = TextEditingController();
  String? message;
  bool loading = false;

  Future<void> _fetchCurrentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final currentUsername = doc.data()?['username'] ?? '';
      usernameController.text = currentUsername;
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = usernameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (newUsername.isEmpty) {
      setState(() => message = "Username cannot be empty.");
      return;
    }

    if (user == null) {
      setState(() => message = "User not found.");
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'username': newUsername});

      setState(() => message = "Username updated successfully.");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() => message = "Failed to update username: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Username")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  color: message!.contains("successfully") ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "New Username"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _updateUsername,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update Username"),
            ),
          ],
        ),
      ),
    );
  }
}
