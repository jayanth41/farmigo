import 'package:flutter/material.dart';
import '../widgets/farmhouse_card.dart';
import '../models/category.dart';
import '../navigation/app_routes.dart';

class PropertiesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  final Category? category;

  const PropertiesGrid({super.key, required this.properties, this.category});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return _buildEmptyState(context, category);
    }
    // Filter out entries with missing or clearly invalid image URLs so the
    // UI doesn't attempt to render cards that will throw decoding errors.
    final valid = properties.where((farmhouse) {
      try {
        final imageUrl = (farmhouse['imageUrl'] ?? farmhouse['image'] ?? '').toString().trim();
        if (imageUrl.isEmpty) return false;
        final lower = imageUrl.toLowerCase();
        // Allow http(s), data URIs and asset references
        if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('data:') || lower.startsWith('assets/')) return true;
        return false;
      } catch (e) {
        debugPrint('PropertiesGrid: skipping item due to invalid image field: $e');
        return false;
      }
    }).toList();

    if (valid.isEmpty) {
      return _buildEmptyState(context, category);
    }

    return Column(
      children: valid.map((farmhouse) {
        // Defensive conversions: data coming from maps may omit keys or be null.
        final idStr = (farmhouse['id'] != null) ? farmhouse['id'].toString() : (farmhouse['name']?.toString() ?? '');
        final nameStr = (farmhouse['name']?.toString() ?? 'Untitled');
        final locationStr = (farmhouse['location']?.toString() ?? 'Unknown location');
        final categoryStr = (farmhouse['category']?.toString() ?? 'Farmhouses');
        final priceVal = (farmhouse['price'] is int)
            ? (farmhouse['price'] as int).toDouble()
            : (farmhouse['price'] as double? ?? 0.0);
        final distanceStr = farmhouse['distance']?.toString() ?? '';
  final imageUrlStr = (farmhouse['imageUrl'] ?? farmhouse['image'] ?? '').toString();
        final imagesList = (farmhouse['images'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final ratingVal = (farmhouse['rating'] is int)
            ? (farmhouse['rating'] as int).toDouble()
            : (farmhouse['rating'] as double? ?? 0.0);
        final reviewsVal = farmhouse['reviews'] as int? ?? 0;
        final amenitiesList = (farmhouse['amenities'] as List?)?.cast<String>() ?? const <String>[];
        final discountVal = farmhouse['discount'] as int?;

        try {
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
        } catch (e) {
          debugPrint('PropertiesGrid: failed to build FarmhouseCard for $idStr — skipping: $e');
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}

Widget _buildEmptyState(BuildContext context, Category? category) {
  String title = 'No properties found';
  IconData icon = Icons.search_off;
  if (category == Category.flights) {
    title = 'Flights booking is coming soon';
    icon = Icons.flight;
  } else if (category == Category.villa) {
    title = 'This category will be available soon';
    icon = Icons.villa;
  } else if (category == Category.car) {
    title = 'This category will be available soon';
    icon = Icons.directions_car;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[500]),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "We’re working on this feature. Please check back later.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            try {
              Navigator.of(context).pushNamed(AppRoutes.home);
            } catch (_) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          child: const Text('Explore Farmhouses'),
        ),
      ],
    ),
  );
}
