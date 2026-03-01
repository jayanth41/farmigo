import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';

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
