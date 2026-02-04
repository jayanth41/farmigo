import 'package:flutter/material.dart';
import '../owner_onboarding_screen.dart';

/// Legacy owner file replaced with a small safe redirect so older imports
/// don't break. Tapping the button opens the owner onboarding flow.
class AddFirstPropertyScreen extends StatelessWidget {
  const AddFirstPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen())),
          child: const Text('Start Owner Onboarding'),
        ),
      ),
    );
  }
}
