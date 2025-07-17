import 'package:flutter/material.dart';

class ProgressMappingPage extends StatelessWidget {
  const ProgressMappingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress Mapping"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.show_chart, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              "Track your cognitive progress",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
