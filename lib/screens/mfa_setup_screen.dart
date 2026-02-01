import 'package:flutter/material.dart';

/// MFA Setup screen is not implemented for the Firebase-only migration.
/// Keeping a simple placeholder so any existing navigation targets remain valid.
class MfaSetupScreen extends StatelessWidget {
  const MfaSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MFA is not available in this build.', style: textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text('The Firebase-only migration currently does not include TOTP enrollment/verification.', style: textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
