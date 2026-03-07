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
    // Do not exclude items just because they lack an image field.
    // Image rendering is handled by ImageWithFallback which shows a
    // placeholder when the URL is empty or fails to load. Keep the
    // original ordering and build a card for each provided property.
    final items = properties;

    if (items.isEmpty) {
      return _buildEmptyState(context, category);
    }

    return Column(
      children: items.map((farmhouse) {
        // Defensive conversions: data coming from maps may omit keys or be null.
    final idStr = (farmhouse['id'] != null) ? farmhouse['id'].toString() : (farmhouse['propertyName']?.toString() ?? '');
    final nameStr = (farmhouse['propertyName']?.toString() ?? farmhouse['name']?.toString() ?? 'Untitled');
    final locationStr = (farmhouse['city']?.toString() ?? farmhouse['location']?.toString() ?? 'Unknown location');
    final categoryStr = (farmhouse['category']?.toString() ?? 'Farmhouses');
    final priceVal = (farmhouse['pricePerNight'] is num)
      ? (farmhouse['pricePerNight'] as num).toDouble()
      : (farmhouse['pricePerNight'] as double? ?? 0.0);
        final distanceStr = farmhouse['distance']?.toString() ?? '';
  // Prefer photoUrls list first, then imageUrl/image fields. If none exist
  // ImageWithFallback will render a placeholder.
  final imagesList = (farmhouse['photoUrls'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
  final imageUrlStr = (imagesList.isNotEmpty)
      ? imagesList.first
      : (farmhouse['imageUrl'] ?? farmhouse['image'] ?? '').toString();
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
          child: const Text('Explore Properties'),
        ),
      ],
    ),
  );
}
