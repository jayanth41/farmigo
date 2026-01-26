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
        // Defensive conversions: data coming from maps may omit keys or be null.
        final idStr = (farmhouse['id'] != null) ? farmhouse['id'].toString() : (farmhouse['name']?.toString() ?? '');
        final nameStr = (farmhouse['name']?.toString() ?? 'Untitled');
        final locationStr = (farmhouse['location']?.toString() ?? 'Unknown location');
        final categoryStr = (farmhouse['category']?.toString() ?? 'Farmhouses');
        final priceVal = (farmhouse['price'] is int)
            ? (farmhouse['price'] as int).toDouble()
            : (farmhouse['price'] as double? ?? 0.0);
        final distanceStr = farmhouse['distance']?.toString() ?? '';
        final imageUrlStr = farmhouse['imageUrl']?.toString() ?? '';
        final imagesList = (farmhouse['images'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final ratingVal = (farmhouse['rating'] is int)
            ? (farmhouse['rating'] as int).toDouble()
            : (farmhouse['rating'] as double? ?? 0.0);
        final reviewsVal = farmhouse['reviews'] as int? ?? 0;
        final amenitiesList = (farmhouse['amenities'] as List?)?.cast<String>() ?? const <String>[];
        final discountVal = farmhouse['discount'] as int?;

        return FarmhouseCard(
          category: categoryStr,
          id: idStr,
          name: nameStr,
          location: locationStr,
          price: priceVal,
          distance: distanceStr,
          imageUrl: imageUrlStr,
          images: imagesList,
          rating: ratingVal,
          reviews: reviewsVal,
          amenities: amenitiesList,
          discount: discountVal,
        );
      }).toList(),
    );
  }
}
