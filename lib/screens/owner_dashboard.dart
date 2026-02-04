import 'package:flutter/material.dart';

/// Minimal Owner Dashboard placeholder kept at the canonical path.
/// This file intentionally contains a tiny, safe widget that other files
/// can import without dragging legacy owner logic back into the app.
class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  import 'package:flutter/material.dart';

  /// Minimal Owner Dashboard placeholder kept at the canonical path.
  /// This file intentionally contains a tiny, safe widget that other files
  /// can import without dragging legacy owner logic back into the app.
  class OwnerDashboard extends StatelessWidget {
    const OwnerDashboard({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Owner Dashboard')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Owner tools are available after onboarding.'),
          ),
        ),
      );
    }
  }
