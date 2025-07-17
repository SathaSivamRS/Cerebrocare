import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TherapistLocatorPage extends StatefulWidget {
  const TherapistLocatorPage({super.key});

  @override
  State<TherapistLocatorPage> createState() => _TherapistLocatorPageState();
}

class _TherapistLocatorPageState extends State<TherapistLocatorPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  double _zoom = 13;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _nearbyPlaces = [];
  double? _distanceInKm;
  String? _travelDuration;
  List<LatLng> _routePoints = [];

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

  Future<void> _getRouteAndDistance(LatLng destination) async {
    if (_currentLocation == null) return;

    final start =
        "${_currentLocation!.longitude},${_currentLocation!.latitude}";
    final end = "${destination.longitude},${destination.latitude}";
    final url = Uri.parse(
      "http://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      final coords = route['geometry']['coordinates'] as List;

      setState(() {
        _routePoints = coords.map((p) => LatLng(p[1], p[0])).toList();
        _distanceInKm = route['distance'] / 1000;
        _travelDuration = _formatDuration(route['duration']);
      });

      _mapController.move(destination, 15);
    } else {
      debugPrint('OSRM API error: ${response.statusCode}');
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return "$minutes min";
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return "$hours hr $rem min";
  }

  void _openInGoogleMaps(LatLng location) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Google Maps');
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    final dest = LatLng(place['lat'], place['lng']);
    _getRouteAndDistance(dest);
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
                              ),
                              if (_routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4,
                                      color: Colors.blue,
                                    ),
                                  ],
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
                                      point: LatLng(place['lat'], place['lng']),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 36,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 30,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoomIn',
                              onPressed: () {
                                setState(() => _zoom += 1);
                                _mapController.move(_currentLocation!, _zoom);
                              },
                              child: const Icon(Icons.zoom_in),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoomOut',
                              onPressed: () {
                                setState(() => _zoom -= 1);
                                _mapController.move(_currentLocation!, _zoom);
                              },
                              child: const Icon(Icons.zoom_out),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_distanceInKm != null && _travelDuration != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Distance: ${_distanceInKm!.toStringAsFixed(2)} km | ETA: $_travelDuration",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyPlaces.length,
                      itemBuilder: (context, index) {
                        final place = _nearbyPlaces[index];
                        final LatLng placeLoc = LatLng(
                          place['lat'],
                          place['lng'],
                        );
                        return GestureDetector(
                          onTap: () => _selectPlace(place),
                          onLongPress: () => _openInGoogleMaps(placeLoc),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
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
