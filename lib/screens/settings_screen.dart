import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../settings/theme_provider.dart';
import '../theme/app_colors.dart';
import 'change_password_screen.dart';
import 'privacy_security_screen.dart';
import 'mfa_setup_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/supabase_config.dart';

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

  final supabase = Supabase.instance.client;
  bool _twoFactorEnabled = false;
  bool _mfaLoading = false;
  List<Map<String, dynamic>> _enrolledFactors = [];

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
                if (v) {
                  // enable 2FA: enroll via REST helper and navigate to setup screen
                  setState(() => _mfaLoading = true);
                  try {
                    final res = await _enrollTotp();
                    if (!mounted) return;
                    setState(() => _mfaLoading = false);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MfaSetupScreen(enrollResponse: res))).then((ok) async {
                      await _loadMfaStatus();
                    });
                  } catch (e) {
                    setState(() => _mfaLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start 2FA: $e')));
                  }
                } else {
                  // disable: require re-authentication first
                  final password = await showDialog<String?>(
                    context: context,
                    builder: (ctx) => _PasswordDialog(),
                  );
                  if (password == null) return; // user cancelled
                  setState(() => _mfaLoading = true);
                  try {
                    // re-authenticate
                    final user = supabase.auth.currentUser;
                    final email = user?.email;
                    if (email == null) throw 'No authenticated user';
                    final signInRes = await supabase.auth.signInWithPassword(email: email, password: password);
                    if (signInRes.user == null) throw 'Re-authentication failed';
                    // Unenroll all factors
                    await _unenrollAll();
                    setState(() => _mfaLoading = false);
                    await _loadMfaStatus();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-factor authentication disabled')));
                  } catch (e) {
                    setState(() => _mfaLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to disable 2FA: $e')));
                  }
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
    _loadMfaStatus();
  }

  Future<void> _loadMfaStatus() async {
    try {
      setState(() => _mfaLoading = true);
      final accessToken = supabase.auth.currentSession?.accessToken;
      final url = '$SUPABASE_URL/auth/v1/mfa';
      final res = await http.get(Uri.parse(url), headers: {
        'apikey': SUPABASE_ANON_KEY,
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          _enrolledFactors = List<Map<String, dynamic>>.from(body);
          setState(() => _twoFactorEnabled = _enrolledFactors.isNotEmpty);
        } else {
          setState(() => _twoFactorEnabled = false);
        }
      } else {
        setState(() => _twoFactorEnabled = false);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _mfaLoading = false);
    }
  }

  Future<Map<String, dynamic>> _enrollTotp() async {
    final accessToken = supabase.auth.currentSession?.accessToken;
    final url = '$SUPABASE_URL/auth/v1/mfa/enroll';
    final res = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'factor_type': 'totp'}));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Enroll failed: ${res.statusCode} ${res.body}');
  }

  Future<void> _unenrollAll() async {
    final accessToken = supabase.auth.currentSession?.accessToken;
    // reload enrolled factors to get ids
    await _loadMfaStatus();
    for (final f in _enrolledFactors) {
      final id = f['id'] ?? f['factor_id'] ?? f['factorId'];
      if (id == null) continue;
      final url = '$SUPABASE_URL/auth/v1/mfa/unenroll';
      await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'factor_id': id}));
    }
    await _loadMfaStatus();
  }

  // Simple password dialog for re-authentication when disabling 2FA
  Widget _PasswordDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Confirm password'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop<String?>(null), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop<String?>(controller.text.trim()), child: const Text('Confirm')),
      ],
    );
  }

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
    // Use AuthController to centralize logout behavior and loading state
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      await auth.signOut();
    } catch (e) {
      // fallback to direct signOut if controller fails
      try {
        await supabase.auth.signOut();
      } catch (_) {}
    }

    // Navigate to login and clear stack
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
