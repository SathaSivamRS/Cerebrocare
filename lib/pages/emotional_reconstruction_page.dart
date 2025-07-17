import 'package:flutter/material.dart';

class EmotionalReconstructionPage extends StatelessWidget {
  const EmotionalReconstructionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emotional Reconstruction"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.self_improvement, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text("Heal and rebuild emotions", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
