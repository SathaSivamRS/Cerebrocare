import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> games = [
      {
        'title': 'Memory Match',
        'image': 'assets/Memory match.png',
        'comingSoon': false,
      },
      {
        'title': 'Recall Rally',
        'image': 'assets/Recall Rally.png',
        'comingSoon': false,
      },
      {
        'title': 'SituActions',
        'image': 'assets/Situactions.png',
        'comingSoon': false,
      },
      {'title': 'Coming Soon', 'image': null, 'comingSoon': true},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔷 Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.videogame_asset_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Brain Games',
                    style: GoogleFonts.lobsterTwo(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Sharpen your mind with quick games 🧠",
                style: GoogleFonts.lobsterTwo(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  itemCount: games.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final game = games[index];

                    return GestureDetector(
                      onTap: () {
                        if (!game['comingSoon']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${game['title']} tapped!")),
                          );
                        }
                      },
                      child: Opacity(
                        opacity: game['comingSoon'] ? 0.6 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (game['image'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    game['image'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.lock_outline,
                                  size: 50,
                                  color: Colors.grey,
                                ),

                              const SizedBox(height: 14),

                              Text(
                                game['title'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lobsterTwo(
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    color:
                                        game['comingSoon']
                                            ? Colors.grey[600]
                                            : Colors.black,
                                  ),
                                ),
                              ),

                              if (game['comingSoon'])
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Coming Soon",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
