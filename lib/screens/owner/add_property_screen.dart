import 'package:flutter/material.dart';
import '../add_property_screen.dart' as top;

/// Deprecated owner-scoped AddPropertyScreen. This file intentionally
/// forwards to the canonical top-level `AddPropertyScreen` so legacy imports
/// don't break. The real implementation lives at `lib/screens/add_property_screen.dart` (root).
class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) => const top.AddPropertyScreen();
}

  // legacy content removed

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fill in the details to list your property', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 18),

                import 'package:flutter/material.dart';
                import '../add_property_screen.dart' as top;

                /// Forwarder to the canonical top-level AddPropertyScreen.
                class AddPropertyScreen extends StatelessWidget {
                  const AddPropertyScreen({super.key});

                  @override
                  Widget build(BuildContext context) => const top.AddPropertyScreen();
                }
                    @override
