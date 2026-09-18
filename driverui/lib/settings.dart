import 'package:flutter/material.dart';

class SettingsDriverScreen extends StatefulWidget {
  const SettingsDriverScreen({Key? key}) : super(key: key);

  @override
  State<SettingsDriverScreen> createState() => _SettingsDriverScreenState();
}

class _SettingsDriverScreenState extends State<SettingsDriverScreen> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with back arrow and title
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button width
                ],
              ),
              const SizedBox(height: 40),

              // Dark Mode Toggle Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF212529), shape: BoxShape.circle),
                          child: const Icon(Icons.dark_mode, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Dark mode', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    Switch(
                      value: _darkMode,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.black87,
                      onChanged: (val) => setState(() => _darkMode = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options Menu Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(Icons.info_outline, 'About application', Colors.black87, () {}),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSettingsItem(Icons.chat_bubble_outline, 'Help/FAQ', Colors.black87, () {}),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSettingsItem(Icons.delete_outline, 'Deactivate my account', Colors.red.shade700, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color textColor, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: textColor == Colors.red.shade700 ? Colors.red.shade50 : const Color(0xFF212529), shape: BoxShape.circle),
        child: Icon(icon, color: textColor == Colors.red.shade700 ? textColor : Colors.white, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }
}