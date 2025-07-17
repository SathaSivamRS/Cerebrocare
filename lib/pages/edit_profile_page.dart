import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentPhone;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentPhone,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCountryCode = "+91"; // Default country code
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;

    // 🔹 Extract country code and phone number properly
    if (widget.currentPhone.isNotEmpty) {
      RegExp phoneRegex = RegExp(r'^\+(\d+)\s*(\d+)$');
      Match? match = phoneRegex.firstMatch(widget.currentPhone);

      if (match != null) {
        _selectedCountryCode = "+${match.group(1)}"; // Extract country code
        _phoneController.text = match.group(2)!; // Extract actual phone number
      } else {
        _phoneController.text = widget.currentPhone;
      }
    }
  }

  Future<void> _saveProfile() async {
    String newName = _nameController.text.trim();
    String newPhone = "$_selectedCountryCode ${_phoneController.text.trim()}";

    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': newName,
          'phone': newPhone,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _image != null
                            ? FileImage(_image!)
                            : const AssetImage("assets/edit_profile.png")
                                as ImageProvider,
                  ),
                  IconButton(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          _image = File(pickedFile.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),

              // Phone Number Field with Country Code Selection
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                initialCountryCode:
                    'IN', // ✅ Default country code set to India (+91)
                onChanged: (phone) {
                  print("Complete Phone Number: ${phone.completeNumber}");
                },
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
