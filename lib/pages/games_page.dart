import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MemorySortGame());

class MemorySortGame extends StatelessWidget {
  const MemorySortGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Sort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const MemorySortScreen(),
    );
  }
}

class MemorySortScreen extends StatefulWidget {
  const MemorySortScreen({super.key});

  @override
  State<MemorySortScreen> createState() => _MemorySortScreenState();
}

class _MemorySortScreenState extends State<MemorySortScreen> {
  int currentLevel = 0;
  final int maxLevel = 5;
  late List<String> originalList;
  late List<String> shuffledList;
  bool showMemory = true;

  final List<List<String>> levelItems = [
    ['🍎 Apple', '🍌 Banana', '🍇 Grapes', '🍓 Strawberry'],
    ['🐶 Dog', '🐱 Cat', '🐭 Mouse', '🦊 Fox', '🐰 Rabbit', '🐻 Bear'],
    [
      '🚗 Car',
      '🚕 Taxi',
      '🚌 Bus',
      '🚓 Police',
      '🏎 Racecar',
      '🚑 Ambulance',
      '🚒 Firetruck',
      '🚜 Tractor',
    ],
    [
      '🏠 House',
      '🏢 Office',
      '🏥 Hospital',
      '🏫 School',
      '🏬 Mall',
      '🏛 Museum',
      '⛪ Church',
      '🏰 Castle',
      '🗼 Tower',
      '🕌 Mosque',
    ],
    [
      '😀 Smile',
      '😢 Cry',
      '😡 Angry',
      '😱 Shocked',
      '🥶 Cold',
      '🥵 Hot',
      '😴 Sleepy',
      '🤓 Nerd',
      '🤠 Cowboy',
      '🥳 Party',
      '😇 Angel',
      '👽 Alien',
    ],
  ];

  @override
  void initState() {
    super.initState();
    loadLevel();
  }

  void loadLevel() {
    originalList = levelItems[currentLevel];
    shuffledList = List.from(originalList)..shuffle();
    showMemory = true;

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          showMemory = false;
        });
      }
    });
  }

  void checkAnswer() {
    if (shuffledList.join() == originalList.join()) {
      if (currentLevel == maxLevel - 1) {
        _showDialog(
          "🎉 Game Complete!",
          "You’ve conquered all levels of Memory Sort!",
          backToHome: true,
        );
      } else {
        _showDialog(
          "✅ Correct!",
          "Get ready for the next level.",
          nextLevel: true,
        );
      }
    } else {
      _showDialog(
        "❌ Wrong Order",
        "Try again to match the sequence correctly.",
        retry: true,
      );
    }
  }

  void _showDialog(
    String title,
    String message, {
    bool nextLevel = false,
    bool retry = false,
    bool backToHome = false,
  }) {
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
                  child: const Text('Next Level'),
                ),
              if (retry)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    loadLevel();
                  },
                  child: const Text('Retry'),
                ),
              if (backToHome)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Home'),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Sort • Level ${currentLevel + 1}/$maxLevel'),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            showMemory
                ? '🧠 Remember this order:'
                : '🔁 Reorder the items correctly:',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  showMemory
                      ? _buildMemoryList(originalList)
                      : _buildReorderableList(),
            ),
          ),
          if (!showMemory)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: checkAnswer,
                icon: const Icon(Icons.check),
                label: const Text('Submit'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoryList(List<String> list) {
    return ListView.separated(
      key: const ValueKey("memory"),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder:
          (context, index) => Card(
            color: Colors.blueGrey,
            child: ListTile(
              title: Text(list[index], style: const TextStyle(fontSize: 20)),
            ),
          ),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView(
      key: const ValueKey("reorder"),
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < shuffledList.length; i++)
          Card(
            key: ValueKey(shuffledList[i]),
            color: Colors.tealAccent.shade200.withOpacity(0.6),
            child: ListTile(
              leading: const Icon(Icons.drag_indicator),
              title: Text(
                shuffledList[i],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
      ],
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = shuffledList.removeAt(oldIndex);
          shuffledList.insert(newIndex, item);
        });
      },
    );
  }
}
