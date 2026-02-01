import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../settings/theme_provider.dart';
import '../theme/app_colors.dart';
import 'change_password_screen.dart';
import 'privacy_security_screen.dart';
// MFA setup screen replaced with a placeholder; import removed to avoid direct dependency.
import 'dart:convert';
import 'package:http/http.dart' as http;
// TOTP/MFA backend integration is not implemented. The UI keeps the
// 2FA toggle but server-side enrollment/unenroll calls are currently
// stubbed to avoid runtime errors until a provider is chosen.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  String language = "English";
  String currency = "USD";
  bool _twoFactorEnabled = false;
  bool _mfaLoading = false;
  // MFA enrollment list removed for Firebase-only migration.

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Notifications"),
          _switchTile(
            "Push Notifications",
            "Receive notifications about bookings",
            pushNotifications,
            (v) => setState(() => pushNotifications = v),
          ),
          _switchTile(
            "Email Notifications",
            "Get updates via email",
            emailNotifications,
            (v) => setState(() => emailNotifications = v),
          ),
          _switchTile(
            "SMS Notifications",
            "Receive SMS alerts",
            smsNotifications,
            (v) => setState(() => smsNotifications = v),
          ),

          _sectionTitle("Appearance"),
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              title: Text("Dark Mode", style: textTheme.bodyLarge),
              subtitle: Text("Use dark theme", style: textTheme.bodyMedium),
              value: themeProvider.isDarkMode,
              activeThumbColor: colorScheme.primary,
              onChanged: (v) {
                themeProvider.toggleDarkMode(v);
              },
            ),
          ),

          _sectionTitle("Language & Region"),
          _dropdownTile(
            "Language",
            language,
            ["English", "Hindi", "Telugu"],
            (v) => setState(() => language = v!),
          ),
          _dropdownTile(
            "Currency",
            currency,
            ["USD", "INR", "EUR"],
            (v) => setState(() => currency = v!),
          ),

          _sectionTitle("Privacy & Security"),
          _arrowTile("Change Password", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
          }),
          _arrowTile("Privacy & Security", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()));
          }),
          // Two-Factor Authentication switch with status
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              title: Text('Two Factor Authentication', style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(_mfaLoading ? 'Checking...' : (_twoFactorEnabled ? 'Enabled' : 'Disabled'), style: Theme.of(context).textTheme.bodyMedium),
              value: _twoFactorEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) async {
                // Note: MFA backend integration is not implemented in this
                // migration. Firebase multi-factor flows are different and
                // aren't implemented here yet. For now we show an informative
                // message and keep the UI intact.
                if (v) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Enrolling in TOTP / MFA is not implemented for Firebase yet.'),
                  ));
                  return;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Disabling MFA is not implemented for Firebase yet.'),
                  ));
                  return;
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "LOGOUT",
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  // MFA status is not yet implemented for the Firebase-only migration.
  // Initialize local flags to conservative defaults.
  _mfaLoading = false;
  _twoFactorEnabled = false;
  }

  // MFA enrollment/unenroll helpers removed — not implemented for Firebase-only migration.

  // Password dialog removed: re-authentication flows for disabling 2FA are
  // not available in the Firebase-only migration stub. If you need
  // re-authentication-based flows, we should implement Firebase reauth.

  // ---------------- UI HELPERS ----------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _dropdownTile(
    String title,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).cardColor,
          style: Theme.of(context).textTheme.bodyLarge,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: Theme.of(context).textTheme.bodyLarge)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _arrowTile(String title, VoidCallback onTap) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface),
        onTap: onTap,
      ),
    );
  }

  // ---------------- LOGOUT ----------------

  Future<void> _logout() async {
    // Directly sign out from Firebase (AuthController also calls this).
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
