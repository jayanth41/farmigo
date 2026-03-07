import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category.dart';
import '../widgets/properties_grid.dart';
import '../controllers/location_controller.dart';
// app_drawer intentionally not used here; navigation remains simple and focused

class CategoryResultsScreen extends StatelessWidget {
  final Category category;
  final List<Map<String, dynamic>> allProperties;

  const CategoryResultsScreen({super.key, required this.category, required this.allProperties});

  @override
  Widget build(BuildContext context) {
    // Filter properties by category label (case-insensitive match)
    final label = category.label.toLowerCase();
    // Respect selected city (if any) so category results only show properties
    // from the chosen city.
    String selectedCity = '';
    try {
      final locCtrl = Get.find<LocationController>();
      selectedCity = locCtrl.selectedCity.value.toLowerCase().trim();
    } catch (_) {}

    final items = allProperties.where((p) {
      try {
        final cat = (p['category'] ?? '').toString().toLowerCase();
        final location = (p['location'] ?? p['city'] ?? '').toString().toLowerCase();
        if (selectedCity.isNotEmpty && !location.contains(selectedCity)) return false;
        return cat.contains(label);
      } catch (_) {
        return false;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(category.label),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: ListView(
          children: [
            PropertiesGrid(properties: items, category: category),
          ],
        ),
      ),
    );
  }
}
