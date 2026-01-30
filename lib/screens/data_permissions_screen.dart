import 'package:flutter/material.dart';

class DataPermissionsScreen extends StatelessWidget {
  const DataPermissionsScreen({super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.location_on, color: colorScheme.primary),
              title: Text('Location usage', style: textTheme.bodyLarge),
              subtitle: Text('Used to show nearby results and map features', style: textTheme.bodyMedium),
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(Icons.sd_storage, color: colorScheme.primary),
              title: Text('Storage usage', style: textTheme.bodyLarge),
              subtitle: Text('Used for caching images and files', style: textTheme.bodyMedium),
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(Icons.notifications, color: colorScheme.primary),
              title: Text('Notification permission', style: textTheme.bodyLarge),
              subtitle: Text('Allow the app to show booking reminders and offers', style: textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
