import 'package:flutter/material.dart';

class BrainTrainingPage extends StatelessWidget {
  const BrainTrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Brain Training"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.psychology_alt, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text("Personalized Brain Training", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
