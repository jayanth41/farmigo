import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings controller when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<SettingsController>().isInitialized) {
        context.read<SettingsController>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<SettingsController>(
        builder: (context, settingsController, child) {
          if (!settingsController.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle("Notifications", Icons.notifications),
              _switchTile(
                title: "Push Notifications",
                subtitle: "Receive notifications about bookings",
                value: settingsController.pushNotifications,
                onChanged: (v) => settingsController.setPushNotifications(v),
              ),
              _switchTile(
                title: "Email Notifications",
                subtitle: "Get updates via email",
                value: settingsController.emailNotifications,
                onChanged: (v) => settingsController.setEmailNotifications(v),
              ),
              _switchTile(
                title: "SMS Notifications",
                subtitle: "Receive SMS alerts",
                value: settingsController.smsNotifications,
                onChanged: (v) => settingsController.setSmsNotifications(v),
              ),

              const SizedBox(height: 20),

              _sectionTitle("Appearance", Icons.dark_mode),
              _switchTile(
                title: "Dark Mode",
                subtitle: "Use dark theme",
                value: settingsController.darkMode,
                onChanged: (v) => settingsController.setDarkMode(v),
              ),

              const SizedBox(height: 20),

              _sectionTitle("Language & Region", Icons.language),
              _dropdownTile(
                title: "Language",
                value: settingsController.language,
                items: const ["English", "Hindi", "Telugu"],
                onChanged: (v) => settingsController.setLanguage(v ?? 'English'),
              ),
              _dropdownTile(
                title: "Currency",
                value: settingsController.currency,
                items: const ["USD", "INR"],
                onChanged: (v) => settingsController.setCurrency(v ?? 'USD'),
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
          );
        },
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
        activeThumbColor: AppColors.primary,
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
