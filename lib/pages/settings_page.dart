import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FF),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Account"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Privacy"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text("Notifications"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logout tapped")),
              );
            },
          ),
        ],
      ),
    );
  }
}
