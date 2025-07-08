import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class TherapistLocatorPage extends StatefulWidget {
  const TherapistLocatorPage({super.key});

  @override
  State<TherapistLocatorPage> createState() => _TherapistLocatorPageState();
}

class _TherapistLocatorPageState extends State<TherapistLocatorPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _nearbyPlaces = [];
  final TextEditingController _searchController = TextEditingController();
  double _zoom = 13;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _loadNearbyPlaces();
    }
  }

  Future<void> _searchByArea(String areaName) async {
    try {
      List<Location> locations = await locationFromAddress(areaName);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _currentLocation = LatLng(loc.latitude, loc.longitude);
        });
        _mapController.move(_currentLocation!, _zoom);
        _loadNearbyPlaces();
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentLocation == null) return;
    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;
    const radius = 2000;

    final query = '''
[out:json];
(
  node["amenity"="hospital"](around:$radius,$lat,$lon);
  node["amenity"="clinic"](around:$radius,$lat,$lon);
  node["healthcare"="psychotherapist"](around:$radius,$lat,$lon);
);
out center;
''';

    final url = Uri.parse("https://overpass-api.de/api/interpreter");
    final response = await http.post(url, body: {'data': query});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final elements = data['elements'] as List;

      setState(() {
        _nearbyPlaces =
            elements.map((e) {
              return {
                'name': e['tags']?['name'] ?? 'Unknown',
                'lat': e['lat'],
                'lng': e['lon'],
                'type':
                    e['tags']?['amenity'] ??
                    e['tags']?['healthcare'] ??
                    'Unknown',
              };
            }).toList();
      });
    } else {
      debugPrint('Overpass API error: ${response.statusCode}');
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom += 1;
      _mapController.move(_currentLocation!, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom -= 1;
      _mapController.move(_currentLocation!, _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F5FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Therapist Locator",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _searchByArea,
                      decoration: InputDecoration(
                        hintText: "Search by area name",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),

                  // Map
                  Stack(
                    children: [
                      Container(
                        height: 300,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentLocation!,
                              initialZoom: _zoom,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.blue,
                                      size: 36,
                                    ),
                                  ),
                                  ..._nearbyPlaces.map((place) {
                                    return Marker(
                                      width: 40,
                                      height: 40,
                                      point: LatLng(place['lat'], place['lng']),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 36,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Zoom Buttons
                      Positioned(
                        top: 12,
                        right: 30,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoomIn',
                              onPressed: _zoomIn,
                              child: const Icon(Icons.zoom_in),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoomOut',
                              onPressed: _zoomOut,
                              child: const Icon(Icons.zoom_out),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Nearby list (vertical)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _nearbyPlaces.length,
                      itemBuilder: (context, index) {
                        final place = _nearbyPlaces[index];
                        return GestureDetector(
                          onTap: () {
                            _mapController.move(
                              LatLng(place['lat'], place['lng']),
                              16,
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Type: ${place['type']}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
