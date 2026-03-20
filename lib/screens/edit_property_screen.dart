import 'package:flutter/material.dart';
import 'add_property_screen.dart';

/// Thin wrapper that reuses `AddPropertyScreen` in edit mode.
/// Keep this file small and stable so all owner call-sites can
/// navigate to an edit route without duplicating the form logic.
class EditPropertyScreen extends StatelessWidget {
  final Map<String, dynamic>? existingData;
  final String? propertyId;

  const EditPropertyScreen({Key? key, this.existingData, this.propertyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddPropertyScreen(
      isEdit: true,
      propertyId: propertyId,
      existingData: existingData,
    );
  }
}

