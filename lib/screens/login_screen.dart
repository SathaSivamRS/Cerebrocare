import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../pages/home_page.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  final AuthService _auth = AuthService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password!")),
      );
      return;
    }

    try {
      String? result = await _auth.signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result == "✅ Login successful!") {
        User? user = FirebaseAuth.instance.currentUser;
        await user?.reload();

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please verify your email. A verification link has been sent.",
              ),
            ),
          );
          return;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login Successful!")));

        await secureStorage.write(
          key: 'email',
          value: emailController.text.trim(),
        );
        await secureStorage.write(
          key: 'password',
          value: passwordController.text.trim(),
        );
        await secureStorage.write(key: 'login_method', value: 'email');
        await _storeUserDeviceData();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? "Something went wrong!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  void loginWithGoogle() async {
    User? user = await _auth.signInWithGoogle();
    if (!mounted) return;

    if (user != null) {
      if (user.emailVerified) {
        final now = FieldValue.serverTimestamp();
        final userDoc = FirebaseFirestore.instance
            .collection("cerebrocare_users")
            .doc(user.uid);

        final userData = {
          'email': user.email,
          'fullName': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'verified': true,
          'createdAt': now,
          'cognitiveStats': {'memory': 0.75, 'mood': 0.75, 'focus': 0.75},
        };

        await userDoc.set(userData, SetOptions(merge: true));
        await secureStorage.write(key: 'login_method', value: 'google');
        await _storeUserDeviceData();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login Successful!")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email first!")),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Google sign-in failed.")));
    }
  }

  Future<void> _storeUserDeviceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final deviceInfo = DeviceInfoPlugin();
    final battery = Battery();
    final packageInfo = await PackageInfo.fromPlatform();
    final position = await Geolocator.getCurrentPosition();

    String deviceModel = '';
    String manufacturer = '';
    String osVersion = '';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceModel = info.model ?? 'Unknown';
      manufacturer = info.manufacturer ?? 'Unknown';
      osVersion = info.version.release ?? 'Unknown';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceModel = info.utsname.machine ?? 'Unknown';
      manufacturer = 'Apple';
      osVersion = info.systemVersion ?? 'Unknown';
    }

    String deviceId = "$deviceModel-$osVersion-${user.uid}";

    await secureStorage.write(key: 'deviceId', value: deviceId);

    final deviceData = {
      'userId': user.uid,
      'email': user.email,
      'deviceModel': deviceModel,
      'manufacturer': manufacturer,
      'osVersion': osVersion,
      'appVersion': packageInfo.version,
      'batteryLevel': await battery.batteryLevel,
      'location': GeoPoint(position.latitude, position.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'forceLogout': false,
    };

    await FirebaseFirestore.instance
        .collection('cerebrocare_devices')
        .doc(deviceId)
        .set(deviceData, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildTextField(emailController, "Email", Icons.email),
                  const SizedBox(height: 15),
                  _buildPasswordField(),
                  const SizedBox(height: 5),
                  _buildForgotPasswordRow(),
                  const SizedBox(height: 20),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildLoginWithSection(),
                  const SizedBox(height: 10),
                  _buildLoginOptions(),
                  const SizedBox(height: 15),
                  _buildSignupOption(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF80D0C7), Color(0xFF13547A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Icon(Icons.lock, size: 80, color: Colors.white),
        SizedBox(height: 10),
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "Login to continue",
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed:
              () => setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        hintText: "Password",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          "Login",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          );
        },
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Color(0xFFFFEB3B)),
        ),
      ),
    );
  }

  Widget _buildLoginWithSection() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white70, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Login with",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white70, thickness: 1)),
      ],
    );
  }

  Widget _buildLoginOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: loginWithGoogle,
          icon: Image.asset("assets/google_logo.png", height: 24),
          label: const Text(
            "Google",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: const Text(
            "Sign up",
            style: TextStyle(
              color: Color(0xFFFFEB3B),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
// dummy line for commit