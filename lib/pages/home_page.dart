import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:login/pages/subscription_page.dart';
import 'package:login/pages/profile_page.dart';
import 'package:login/pages/faq_page.dart';
import 'package:login/screens/login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userName;

  final List<Widget> _pages = [
    const HomePageContent(),
    const SubscriptionPage(),
    const ProfilePage(),
    const FAQPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _startForceLogoutListener();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('cerebrocare_users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && mounted) {
          setState(() {
            _userName = data['fullName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Failed to fetch user name: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final storage = FlutterSecureStorage();
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _startForceLogoutListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storage = FlutterSecureStorage();
    final deviceId = await storage.read(key: 'deviceId');
    if (deviceId == null) return;

    FirebaseFirestore.instance
        .collection('cerebrocare_devices')
        .doc(deviceId)
        .snapshots()
        .listen((docSnapshot) async {
          final data = docSnapshot.data();
          if (data != null && data['forceLogout'] == true) {
            await FirebaseFirestore.instance
                .collection('cerebrocare_devices')
                .doc(deviceId)
                .update({'forceLogout': false});

            await FirebaseAuth.instance.signOut();
            await storage.deleteAll();

            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          bool shouldExit = await _showLogoutConfirmation(context);
          if (shouldExit) {
            _logout();
          }
        }
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions),
              label: "Subscription",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(Icons.help), label: "FAQ"),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.purple,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFFDF5FF),
        child: Column(
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 40,
                bottom: 14,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Hi, Buddy 👋",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.biotech, color: Colors.white, size: 24),
                      SizedBox(width: 6),
                      Text(
                        "CerebroCare",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Ready for a quick brain boost?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _buildCognitiveStatusCard(),
            const SizedBox(height: 30),
            _buildGridIcons(),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Assistive tools\n★ Voice prompts & Media-Based Memory",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCognitiveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Cognitive status",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDonut("Memory", Colors.orange),
              _buildDonut("Focus", Colors.green),
              _buildDonut("Mood", Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonut(String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const Text("75%"),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGridIcons() {
    final items = [
      ["Personalized Brain Training", Icons.psychology_alt],
      ["Therapist Locator", Icons.medical_services],
      ["Emotional Reconstruction", Icons.self_improvement],
      ["Progress Mapping", Icons.show_chart],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        children:
            items.map((e) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black,
                    child: Icon(
                      e[1] as IconData,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e[0] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
