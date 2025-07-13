import 'package:flutter/material.dart';
import 'dart:async';

class RecallRallyScreen extends StatefulWidget {
  const RecallRallyScreen({super.key});

  @override
  State<RecallRallyScreen> createState() => _RecallRallyScreenState();
}

class _RecallRallyScreenState extends State<RecallRallyScreen> {
  int currentLevel = 0;
  final int maxLevel = 5;
  late List<String> originalList;
  late List<String> shuffledList;
  bool showMemory = true;

  final List<List<String>> levelItems = [
    ['🧠 Brain', '👀 Eyes', '👂 Ears', '👃 Nose'],
    ['🛴 Scooter', '🚲 Bicycle', '🛵 Moped', '🏍 Motorcycle', '🚗 Car'],
    ['📱 Phone', '💻 Laptop', '🖥 Monitor', '⌚ Watch', '🕹 Gamepad'],
    ['🌞 Sun', '🌧 Rain', '🌨 Snow', '🌈 Rainbow', '🌪 Tornado', '🌫 Fog'],
    [
      '🧃 Juice',
      '🥛 Milk',
      '☕ Coffee',
      '🍵 Tea',
      '🧋 Boba',
      '🥤 Soda',
      '🍺 Beer',
    ],
  ];

  @override
  void initState() {
    super.initState();
    loadLevel();
  }

  void loadLevel() {
    originalList = List<String>.from(levelItems[currentLevel]);
    shuffledList = List<String>.from(originalList)..shuffle();
    setState(() => showMemory = true);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => showMemory = false);
      }
    });
  }

  void checkAnswer() {
    bool isCorrect = true;
    for (int i = 0; i < originalList.length; i++) {
      if (originalList[i] != shuffledList[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      if (currentLevel == maxLevel - 1) {
        _showDialog(
          title: "🏁 Rally Complete!",
          message: "You’ve mastered all stages of Recall Rally!",
          backToHome: true,
        );
      } else {
        _showDialog(
          title: "✅ Correct!",
          message: "Next round is about to begin.",
          nextLevel: true,
        );
      }
    } else {
      _showDialog(
        title: "❌ Wrong Order",
        message: "Try again to recall the sequence correctly.",
        retry: true,
      );
    }
  }

  void _showDialog({
    required String title,
    required String message,
    bool nextLevel = false,
    bool retry = false,
    bool backToHome = false,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              if (nextLevel)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      currentLevel++;
                      loadLevel();
                    });
                  },
                  child: const Text("Next Level"),
                ),
              if (retry)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    loadLevel();
                  },
                  child: const Text("Retry"),
                ),
              if (backToHome)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.maybePop(context);
                  },
                  child: const Text("Back to Home"),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        title: Text("Recall Rally • Level ${currentLevel + 1}/$maxLevel"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            showMemory
                ? "🔍 Remember this sequence:"
                : "🔁 Reorder the sequence correctly:",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  showMemory
                      ? _buildMemoryList(originalList)
                      : _buildReorderableList(shuffledList),
            ),
          ),
          if (!showMemory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                onPressed: checkAnswer,
                icon: const Icon(Icons.check),
                label: const Text("Submit"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoryList(List<String> list) {
    return ListView.builder(
      key: const ValueKey("memory"),
      itemCount: list.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Card(
          color: Colors.deepOrange.shade400,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
              list[index],
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableList(List<String> list) {
    return ReorderableListView.builder(
      key: const ValueKey("reorder"),
      itemCount: list.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Card(
          key: ValueKey(list[index]),
          color: Colors.orange.shade100.withOpacity(0.7),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.drag_handle, color: Colors.black54),
            title: Text(
              list[index],
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
        });
      },
    );
  }
}
