import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chatbot_screen.dart';
import 'virtual_assistant_screen.dart';
import '../main.dart'; // themeNotifier

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.tealAccent],
                ),
              ),
              accountName: const Text('Welcome'),
              accountEmail: Text(user?.email ?? 'User'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.teal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('DocBuddy Home'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0f7fa), Color(0xFFffffff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: size.height * 0.25,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.local_hospital, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Hello 👋",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Need medical help? Ask DocBuddy anything!",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'DocChat Bot',
                      icon: Icons.chat_bubble_outline,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      context,
                      title: 'Virtual Assistant',
                      icon: Icons.mic_none_rounded,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VirtualAssistantScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
