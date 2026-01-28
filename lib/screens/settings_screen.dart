import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotif = true;
  bool emailNotif = true;
  bool smsNotif = false;
  bool darkMode = false;

  String language = "English";
  String currency = "USD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Notifications", Icons.notifications),
          _switchTile(
            title: "Push Notifications",
            subtitle: "Receive notifications about bookings",
            value: pushNotif,
            onChanged: (v) => setState(() => pushNotif = v),
          ),
          _switchTile(
            title: "Email Notifications",
            subtitle: "Get updates via email",
            value: emailNotif,
            onChanged: (v) => setState(() => emailNotif = v),
          ),
          _switchTile(
            title: "SMS Notifications",
            subtitle: "Receive SMS alerts",
            value: smsNotif,
            onChanged: (v) => setState(() => smsNotif = v),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Appearance", Icons.dark_mode),
          _switchTile(
            title: "Dark Mode",
            subtitle: "Use dark theme",
            value: darkMode,
            onChanged: (v) => setState(() => darkMode = v),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Language & Region", Icons.language),
          _dropdownTile(
            title: "Language",
            value: language,
            items: const ["English", "Hindi", "Telugu"],
            onChanged: (v) => setState(() => language = v!),
          ),
          _dropdownTile(
            title: "Currency",
            value: currency,
            items: const ["USD", "INR"],
            onChanged: (v) => setState(() => currency = v!),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Privacy & Security", Icons.lock),
          _navTile("Change Password"),
          _navTile("Privacy Settings"),
          _navTile("Two-Factor Authentication"),

          const SizedBox(height: 20),

          _sectionTitle("Data & Storage", Icons.storage),
          _actionTile(
            title: "Clear Cache",
            color: Colors.orange,
            onTap: () {},
          ),
          _actionTile(
            title: "Delete Account",
            color: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ---------- WIDGETS ----------

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _dropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        title: Text(title),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: items
              .map(
                (e) => DropdownMenuItem(value: e, child: Text(e)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _navTile(String title) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        title: Text(title, style: TextStyle(color: color)),
        onTap: onTap,
      ),
    );
  }
}
