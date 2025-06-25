
import 'package:flutter/material.dart';

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Medical Services"),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          "Coming soon: Locate nearby hospitals and medical stores!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
