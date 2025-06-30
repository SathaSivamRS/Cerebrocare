import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

// import 'package:login/widgets/live_location_map.dart'; // add this import
import 'package:login/pages/track_phone_page.dart';
import 'package:login/pages/find_device_page.dart';
import 'package:login/pages/register_device_page.dart';
import 'package:login/pages/face_data_page.dart';
import 'package:login/pages/nominee_page.dart';
import 'package:login/pages/app_protection_page.dart';
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

  final List<Widget> _pages = [
    const HomePageContent(),
    const SubscriptionPage(),
    const ProfilePage(),
    const FAQPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
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
        appBar:
            _selectedIndex == 0
                ? AppBar(
                  backgroundColor: Colors.purple,
                  title: const Text("Home"),
                )
                : null,
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
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
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
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
    }

    _location.onLocationChanged.listen((newLoc) {
      setState(() {
        _currentPosition = LatLng(newLoc.latitude!, newLoc.longitude!);
      });
      _mapController.move(_currentPosition!, _mapController.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackPhonePage()),
              );
            },
            child: _buildMap(context),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                _buildButtonRow(context, [
                  _buildRoundButton(
                    context,
                    Icons.location_searching,
                    "Track Phone",
                    const TrackPhonePage(),
                  ),
                  _buildRoundButton(
                    context,
                    Icons.search,
                    "Find Device",
                    const FindDevicePage(),
                  ),
                  _buildRoundButton(
                    context,
                    Icons.devices,
                    "Register Device",
                    RegisterDevicePage(),
                  ),
                ]),
                const SizedBox(height: 15),
                _buildButtonRow(context, [
                  _buildRoundButton(
                    context,
                    Icons.face,
                    "Add Face Data",
                    const FaceDataPage(),
                  ),
                  _buildRoundButton(
                    context,
                    Icons.person_add,
                    "Add Nominees",
                    const NomineePage(),
                  ),
                  _buildRoundButton(
                    context,
                    Icons.security,
                    "App Protection",
                    const AppProtectionPage(),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 16,
                        onTap: (_, __) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TrackPhonePage(),
                            ),
                          );
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
        if (_currentPosition != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: true,
              onPressed: () {
                _mapController.move(_currentPosition!, 16);
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildButtonRow(BuildContext context, List<Widget> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  Widget _buildRoundButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple,
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 90,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
