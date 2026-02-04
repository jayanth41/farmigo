import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/properties_grid.dart';
// app_drawer intentionally not used here; navigation remains simple and focused

class CategoryResultsScreen extends StatelessWidget {
  final Category category;
  final List<Map<String, dynamic>> allProperties;

  const CategoryResultsScreen({super.key, required this.category, required this.allProperties});

  @override
  Widget build(BuildContext context) {
    // Filter properties by category label (case-insensitive match)
    final label = category.label.toLowerCase();
    final items = allProperties.where((p) {
      try {
        final cat = (p['category'] ?? '').toString().toLowerCase();
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
