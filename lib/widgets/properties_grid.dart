import 'package:flutter/material.dart';
import '../widgets/farmhouse_card.dart';

class PropertiesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> properties;

  const PropertiesGrid({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No properties found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: properties.map((farmhouse) {
        return FarmhouseCard(
          category: farmhouse['category'] as String? ?? 'Farmhouses',
          name: farmhouse['name'],
          location: farmhouse['location'],
          price: (farmhouse['price'] is int) ? (farmhouse['price'] as int).toDouble() : (farmhouse['price'] as double? ?? 0.0),
          distance: farmhouse['distance'] ?? '',
          imageUrl: farmhouse['imageUrl'] ?? '',
          images: List<String>.from(farmhouse['images'] ?? []),
          rating: (farmhouse['rating'] is int) ? (farmhouse['rating'] as int).toDouble() : (farmhouse['rating'] as double? ?? 0.0),
          reviews: farmhouse['reviews'] as int? ?? 0,
          amenities: (farmhouse['amenities'] as List?)?.cast<String>() ?? const [],
          discount: farmhouse['discount'] as int?,
        );
      }).toList(),
    );
  }
}
