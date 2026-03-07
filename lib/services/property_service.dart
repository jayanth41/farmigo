import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../data/farmhouses_data.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a single property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      debugPrint('   📦 Querying Firestore: collection=properties, docId=$propertyId');
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      debugPrint('   ✅ Document exists: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('   ✅ Document data retrieved: ${data['name']}');
        return PropertyModel.fromJson({...data, 'id': doc.id});
      } else {
        debugPrint('   ❌ Document does not exist with ID: $propertyId');
        // Fallback: check local farmhouses data (useful for demo/local seeded data)
        try {
          final local = farmhousesData.firstWhere(
            (f) => (f['id']?.toString() ?? '') == propertyId,
            orElse: () => {},
          );
          if (local.isNotEmpty) {
            debugPrint('   ℹ️ Found local farmhouse data for id=$propertyId, mapping to PropertyModel');
            // Map local farmhouse fields to PropertyModel shape
      // Ensure we have at least one usable image URL to avoid Image.network 404 spam.
      final rawImages = (local['images'] as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .toList() ??
        [(local['imageUrl']?.toString() ?? '')];
      final cleanedImages = rawImages.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      const String placeholderImage = 'https://via.placeholder.com/800x600.png?text=No+Image';
      final imageUrlsFinal = cleanedImages.isNotEmpty ? cleanedImages : [placeholderImage];

      final mapped = <String, dynamic>{
              'id': local['id'] ?? propertyId,
              'userId': local['ownerId'] ?? '',
              'name': local['name'] ?? '',
              'description': local['description'] ?? local['name'] ?? '',
              'category': local['category'] ?? 'Farmhouses',
              'city': (local['location'] as String?)?.split(',').first.trim() ?? '',
              'state': local['state'] ?? '',
              'latitude': local['latitude'] ?? 0.0,
              'longitude': local['longitude'] ?? 0.0,
        'pricePerNight': (local['price'] ?? 0) is String
          ? double.tryParse(local['price']) ?? 0.0
          : (local['price'] ?? 0).toDouble(),
              'bedrooms': local['bedrooms'] ?? 0,
              'bathrooms': local['bathrooms'] ?? 0,
              'maxGuests': local['maxGuests'] ?? 0,
              'minStay': local['minStay'] ?? 1,
              'imageUrls': imageUrlsFinal,
              'highlights': local['highlights'] ?? [],
              'amenities': local['amenities'] ?? [],
              'policies': local['policies'] ?? {},
              'timings': local['timings'] ?? {},
              'nearbyAttractions': local['nearbyAttractions'] ?? [],
              'averageRating': local['rating'] ?? 0.0,
              'reviewCount': local['reviews'] ?? 0,
              'instantBooking': local['instantBooking'] ?? false,
              'isActive': local['isActive'] ?? true,
              'createdAt': local['createdAt'] ?? DateTime.now().toIso8601String(),
              'ownerDetails': local['ownerDetails'],
            };

            return PropertyModel.fromJson(mapped);
          }
        } catch (e) {
          debugPrint('   ❌ Error checking local farmhouses data: $e');
        }
      }
      return null;
    } catch (e) {
      debugPrint('   ❌ Error fetching property: $e');
      return null;
    }
  }

  /// Get all properties
  Future<List<PropertyModel>> getAllProperties() async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      return [];
    }
  }

  /// Get properties by category
  Future<List<PropertyModel>> getPropertiesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching properties by category: $e');
      return [];
    }
  }

  /// Get properties by city
  Future<List<PropertyModel>> getPropertiesByCity(String city) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching properties by city: $e');
      return [];
    }
  }

  /// Get similar properties (same category and city)
  Future<List<PropertyModel>> getSimilarProperties({
    required String category,
    required String city,
    required String currentPropertyId,
    int limit = 5,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('category', isEqualTo: category)
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .limit(limit + 1)
          .get();
      
      final properties = querySnapshot.docs
          .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
          .where((p) => p.id != currentPropertyId)
          .take(limit)
          .toList();
      
      return properties;
    } catch (e) {
      debugPrint('Error fetching similar properties: $e');
      return [];
    }
  }

  /// Update property with new data
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating property: $e');
      return false;
    }
  }
}
