import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class DataPermissionsScreen extends StatefulWidget {
  const DataPermissionsScreen({super.key});

  @override
  State<DataPermissionsScreen> createState() => _DataPermissionsScreenState();
}

class _DataPermissionsScreenState extends State<DataPermissionsScreen> {
  bool _locationEnabled = false;
  bool _notificationsEnabled = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStates();
  }

  Future<void> _refreshPermissionStates() async {
    setState(() => _checking = true);
    try {
      final locStatus = await Permission.locationWhenInUse.status;
      final notifStatus = await Permission.notification.status;

      setState(() {
        _locationEnabled = locStatus.isGranted;
        _notificationsEnabled = notifStatus.isGranted;
      });
    } catch (_) {
      // best-effort; leave defaults
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _onLocationToggle(bool newValue) async {
    // Show confirmation before redirecting to system settings.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location permission is required'),
        content: const Text('Location permission is required to show nearby results.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OPEN SETTINGS')),
        ],
      ),
    );

    if (confirmed == true) {
      await openAppSettings();
      // Re-check permission after returning from settings.
      await _refreshPermissionStates();
    }
  }

  Future<void> _onNotificationToggle(bool newValue) async {
    // For notifications we redirect user to system notification settings.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification permission'),
        content: const Text('To change notification settings, we will open system settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OPEN SETTINGS')),
        ],
      ),
    );

    if (confirmed == true) {
      await openAppSettings();
      await _refreshPermissionStates();
    }
  }

  Future<void> _clearCache() async {
    try {
  // Clear Flutter image cache
  imageCache.clear();
  imageCache.clearLiveImages();

      // Clear temporary directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final file in tempDir.list(recursive: true)) {
          try {
            if (file is File) await file.delete();
            if (file is Directory) await file.delete(recursive: true);
          } catch (_) {
            // ignore individual failures
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear cache: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Usage & Permissions', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.location_on, color: colorScheme.primary),
                title: Text('Location access', style: textTheme.bodyLarge),
                subtitle: Text('Show nearby farmhouses and map features', style: textTheme.bodyMedium),
                trailing: _checking
                    ? SizedBox(width: 48, height: 24, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))))
                    : Switch(
                        value: _locationEnabled,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (v) => _onLocationToggle(v),
                      ),
                onTap: () => _onLocationToggle(!_locationEnabled),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.notifications, color: colorScheme.primary),
                title: Text('Notifications', style: textTheme.bodyLarge),
                subtitle: Text('Get booking reminders and offers', style: textTheme.bodyMedium),
                trailing: _checking
                    ? SizedBox(width: 48, height: 24, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))))
                    : Switch(
                        value: _notificationsEnabled,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (v) => _onNotificationToggle(v),
                      ),
                onTap: () => _onNotificationToggle(!_notificationsEnabled),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.sd_storage, color: colorScheme.primary),
                title: Text('Clear cache', style: textTheme.bodyLarge),
                subtitle: Text('Used for caching images and files', style: textTheme.bodyMedium),
                trailing: ElevatedButton(
                  onPressed: _clearCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Clear cache'),
                ),
                onTap: _clearCache,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'We only use your data to improve your booking experience. We never sell your data.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
