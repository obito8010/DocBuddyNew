import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailController = TextEditingController();
  String? message;
  bool loading = false;

  void handleReset() async {
    setState(() { message = null; loading = true; });
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => message = "Email is required");
    } else {
      await FirebaseAuthService.resetPassword(email);
      setState(() => message = "Password reset link sent, check your email.");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text("Reset Password")),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (message != null) Text(message!, style: const TextStyle(color: Colors.green)),
          const SizedBox(height: 10),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: "Your Email")),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : handleReset,
            child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Send Reset Email"),
          ),
        ],
      ),
    ),
  );
}
