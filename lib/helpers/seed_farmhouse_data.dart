import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/farmhouses_data.dart';

/// Seeds the Firestore 'properties' collection with farmhouse data from farmhouses_data.dart
class SeedFarmhouseData {
  static Future<void> seedAllProperties() async {
    final firestore = FirebaseFirestore.instance;
    
    for (var property in farmhousesData) {
      final propertyId = property['id'] as String?;
      if (propertyId == null) continue;
      
      try {
        // Check if document already exists
        final docSnapshot = await firestore
            .collection('properties')
            .doc(propertyId)
            .get();
        
        if (!docSnapshot.exists) {
          // Create new document with data from farmhouses_data
          await firestore
              .collection('properties')
              .doc(propertyId)
              .set({
            'id': propertyId,
            'name': property['name'] ?? '',
            'location': property['location'] ?? '',
            'state': property['state'] ?? '',
            'category': property['category'] ?? '',
            'price': property['price'] ?? 0.0,
            'distance': property['distance'] ?? '',
            'rating': property['rating'] ?? 0.0,
            'reviews': property['reviews'] ?? 0,
            'amenities': property['amenities'] ?? [],
            'imageUrl': property['imageUrl'] ?? '',
            'images': property['images'] ?? [],
            'discount': property['discount'] ?? 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ Created property: ${property['name']} (ID: $propertyId)');
        } else {
          print('⏭️  Property already exists: ${property['name']} (ID: $propertyId)');
        }
      } catch (e) {
        print('❌ Error seeding ${property['name']}: $e');
      }
    }
  }

  /// Seeds individual property
  static Future<void> seedProperty(String propertyId) async {
    final firestore = FirebaseFirestore.instance;
    
    // Find property in data
    final property = farmhousesData.firstWhere(
      (p) => p['id'] == propertyId,
      orElse: () => {},
    );
    
    if (property.isEmpty) {
      print('❌ Property not found in data: $propertyId');
      return;
    }
    
    try {
      await firestore
          .collection('properties')
          .doc(propertyId)
          .set({
        'id': propertyId,
        'name': property['name'] ?? '',
        'location': property['location'] ?? '',
        'state': property['state'] ?? '',
        'category': property['category'] ?? '',
        'price': property['price'] ?? 0.0,
        'distance': property['distance'] ?? '',
        'rating': property['rating'] ?? 0.0,
        'reviews': property['reviews'] ?? 0,
        'amenities': property['amenities'] ?? [],
        'imageUrl': property['imageUrl'] ?? '',
        'images': property['images'] ?? [],
        'discount': property['discount'] ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Seeded property: ${property['name']} (ID: $propertyId)');
    } catch (e) {
      print('❌ Error seeding property: $e');
    }
  }
}
