import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? message;
  bool loading = false;

  void handleUpdatePassword() async {
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      message = null;
      loading = true;
    });

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        message = "Please fill in all fields.";
        loading = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        message = "Passwords do not match.";
        loading = false;
      });
      return;
    }

    final error = await FirebaseAuthService.updatePassword(newPassword);

    setState(() {
      message = error ?? "Password updated successfully!";
      loading = false;
    });

    if (error == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  color: message!.contains("success") ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : handleUpdatePassword,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update Password"),
            ),
          ],
        ),
      ),
    );
  }
}
