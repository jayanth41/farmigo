import 'package:flutter/material.dart';
import 'data_permissions_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _hideProfile = false;
  bool _hideBookings = false;
  bool _personalizedAds = true;

  void _confirmClearSearch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Do you want to clear search history?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search history cleared')));
      // mock behavior: nothing else to do
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Security', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Hide Profile Information', style: textTheme.bodyLarge),
            subtitle: Text('When ON, profile details are hidden (UI only)', style: textTheme.bodyMedium),
            value: _hideProfile,
            onChanged: (v) => setState(() => _hideProfile = v),
            secondary: Icon(Icons.person_off, color: colorScheme.onSurface),
          ),

          SwitchListTile(
            title: Text('Hide Booking History', style: textTheme.bodyLarge),
            subtitle: Text('When ON, booking history will be hidden (mock)', style: textTheme.bodyMedium),
            value: _hideBookings,
            onChanged: (v) => setState(() => _hideBookings = v),
            secondary: Icon(Icons.history_toggle_off, color: colorScheme.onSurface),
          ),

          ListTile(
            leading: Icon(Icons.delete_outline, color: colorScheme.onSurface),
            title: Text('Clear Search History', style: textTheme.bodyLarge),
            onTap: _confirmClearSearch,
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface),
          ),

          SwitchListTile(
            title: Text('Personalized Ads', style: textTheme.bodyLarge),
            subtitle: Text('Allow ads tailored to your interests', style: textTheme.bodyMedium),
            value: _personalizedAds,
            onChanged: (v) => setState(() => _personalizedAds = v),
            secondary: Icon(Icons.ad_units, color: colorScheme.onSurface),
          ),

          ListTile(
            leading: Icon(Icons.data_usage, color: colorScheme.onSurface),
            title: Text('Data Usage & Permissions', style: textTheme.bodyLarge),
            subtitle: Text('View permissions and usage info', style: textTheme.bodyMedium),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataPermissionsScreen())),
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
