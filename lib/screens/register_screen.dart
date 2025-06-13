import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'home_screen.dart'; // ✅ Redirect here after registration
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? error, success;
  bool loading = false;

  void handleRegister() async {
    setState(() {
      error = success = null;
      loading = true;
    });

    final email = emailController.text.trim();
    final pass = passwordController.text;
    final confirm = confirmController.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() {
        error = "All fields are required.";
        loading = false;
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        error = "Passwords do not match.";
        loading = false;
      });
      return;
    }

    final err = await FirebaseAuthService.register(email, pass);
    setState(() => loading = false);

    if (err == null) {
      setState(() => success = "Registration successful! Redirecting…");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    } else {
      setState(() => error = err);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Register - DocBuddy")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (success != null)
                Text(success!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm Password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : handleRegister,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      );
}
