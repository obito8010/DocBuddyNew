import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'home_screen.dart'; // ✅ Import HomeScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;
  bool loading = false;

  void handleLogin() async {
    setState(() {
      loading = true;
      error = null;
    });

    final err = await FirebaseAuthService.login(
      emailController.text.trim(),
      passwordController.text,
    );

    setState(() {
      loading = false;
    });

    if (err == null) {
      // ✅ Navigate to HomeScreen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("DocBuddy Login")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 80),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : handleLogin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text("Don't have an account? Register"),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                ),
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      );
}
