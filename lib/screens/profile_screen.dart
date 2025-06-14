import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'login_screen.dart';
import 'update_username_screen.dart';
import 'update_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuthService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              final err = await FirebaseAuthService.deleteAccount();
              if (err == null) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      title: const Text(
        "My Profile",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18, // Reduced text size
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white), // White back icon
      toolbarHeight: 45, // Reduced height
    ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Profile Card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: user == null
                      ? const Center(child: Text("No user logged in.", style: TextStyle(color: Colors.white)))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Email:",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              user.email ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Buttons
                            CustomProfileButton(
                              icon: Icons.edit,
                              label: "Update Username",
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UpdateUsernameScreen()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomProfileButton(
                              icon: Icons.lock,
                              label: "Update Password",
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomProfileButton(
                              icon: Icons.delete_forever,
                              label: "Delete Account",
                              color: Colors.redAccent,
                              onPressed: () => _deleteAccount(context),
                            ),
                            const SizedBox(height: 30),
                            TextButton.icon(
                              onPressed: () => _logout(context),
                              icon: const Icon(Icons.logout, color: Colors.white70),
                              label: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const CustomProfileButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.tealAccent[700],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}
