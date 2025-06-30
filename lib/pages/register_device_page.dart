import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RegisterDevicePage extends StatefulWidget {
  @override
  State<RegisterDevicePage> createState() => _RegisterDevicePageState();
}

class _RegisterDevicePageState extends State<RegisterDevicePage> {
  String? error;
  bool isRegistering = false;

  Future<void> registerDevice() async {
    setState(() {
      isRegistering = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfoPlugin = DeviceInfoPlugin();
      final battery = Battery();
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) throw Exception("Location service not enabled");
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception("Location permission not granted");
        }
      }

      final locationData = await location.getLocation();
      final batteryLevel = await battery.batteryLevel;
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      Map<String, dynamic> deviceData = {
        'userId': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'appVersion': packageInfo.version,
        'batteryLevel': batteryLevel,
        'lastUpdated': formattedDate,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      };

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData.addAll({
          'deviceModel': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'osVersion': 'Android ${androidInfo.version.release}',
        });
      } else {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData.addAll({
          'deviceModel': iosInfo.utsname.machine,
          'manufacturer': 'Apple',
          'osVersion': 'iOS ${iosInfo.systemVersion}',
        });
      }

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(user.uid)
          .set(deviceData, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Device registered successfully")));
    } catch (e) {
      setState(() {
        error = "❌ Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register Device")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red, fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: isRegistering ? null : registerDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isRegistering
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                        "Register Device",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
