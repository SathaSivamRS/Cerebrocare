import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MemoryMatchGame());

class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Match Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const GameScreen(),
    );
  }
}

class GameCard {
  final String emoji;
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> emojis = ['🧠', '🚀', '🎯', '🔥', '🎮', '👾', '🌟', '💎'];
  late List<GameCard> cards;
  GameCard? firstCard;
  GameCard? secondCard;
  int score = 0;
  bool boardLocked = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    final gameEmojis = [...emojis, ...emojis]..shuffle(Random());
    cards = gameEmojis.map((e) => GameCard(emoji: e)).toList();
    firstCard = null;
    secondCard = null;
    score = 0;
    boardLocked = false;
    setState(() {});
  }

  void flipCard(int index) {
    if (boardLocked || cards[index].isFlipped || cards[index].isMatched) return;

    setState(() {
      cards[index].isFlipped = true;
    });

    if (firstCard == null) {
      firstCard = cards[index];
    } else {
      secondCard = cards[index];
      boardLocked = true;

      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() {
          if (firstCard!.emoji == secondCard!.emoji) {
            firstCard!.isMatched = true;
            secondCard!.isMatched = true;
            score++;

            if (cards.every((c) => c.isMatched)) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => AlertDialog(
                      title: const Text(
                        '🎉 Victory!',
                        textAlign: TextAlign.center,
                      ),
                      content: Text('You matched all pairs!\nScore: $score'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            startGame();
                          },
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
              );
            }
          } else {
            firstCard!.isFlipped = false;
            secondCard!.isFlipped = false;
          }

          firstCard = null;
          secondCard = null;
          boardLocked = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final cardHeight = (screenHeight - appBarHeight - statusBarHeight - 80) / 4;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Memory Match Game'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: startGame),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    childAspectRatio: 2 / 3,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () => flipCard(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color:
                              card.isMatched
                                  ? Colors.lightGreenAccent.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            card.isFlipped || card.isMatched ? card.emoji : '❓',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
