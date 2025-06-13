import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'login_screen.dart';
import 'update_username_screen.dart';
import 'update_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext c) async {
    await FirebaseAuthService.logout();
    Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _deleteAccount(BuildContext c) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(c)),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(c);
              final err = await FirebaseAuthService.deleteAccount();
              if (err == null) {
                Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              } else {
                ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err)));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final user = FirebaseAuthService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: user == null
          ? const Center(child: Text("No user logged in."))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Email: ${user.email}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const UpdateUsernameScreen())), child: const Text("Update Username")),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const UpdatePasswordScreen())), child: const Text("Update Password")),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _deleteAccount(c),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete Account"),
                ),
                const SizedBox(height: 30),
                TextButton(onPressed: () => _logout(c), child: const Text("Logout")),
              ]),
            ),
    );
  }
}
