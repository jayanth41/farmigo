import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to create test properties in Firestore for development/testing
class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a sample test property in Firestore
  static Future<String?> createTestProperty({
    String? propertyName,
    String? city = 'Lonavala',
    String? category = 'Farmhouse',
  }) async {
    try {
      final testProperty = {
        'name': propertyName ?? 'Beautiful Farmhouse',
        'description':
            'A serene farmhouse located in the hills with beautiful views and modern amenities.',
        'city': city,
        'state': 'Maharashtra',
        'category': category,
        'pricePerNight': 5000.0,
        'averageRating': 4.5,
        'reviewCount': 12,
        'imageUrls': [
          'https://images.unsplash.com/photo-1570129477492-45a003cc3600?w=500',
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=500',
          'https://images.unsplash.com/photo-1494959764132-baee4a7b2f49?w=500',
        ],
        'highlights': ['Free WiFi', 'Swimming Pool', 'Garden', 'Parking'],
        'amenities': ['WiFi', 'AC', 'Hot Water', 'Kitchen', 'TV', 'Parking'],
        'timings': {
          'checkInTime': '2:00 PM',
          'checkOutTime': '11:00 AM',
        },
        'latitude': 18.7515,
        'longitude': 73.4008,
        'userId': 'owner123',
        'ownerDetails': {
          'name': 'John Doe',
          'image':
              'https://ui-avatars.com/api/?name=John+Doe&background=random',
          'contact': '+91-9876543210',
          'isVerified': true,
        },
        'nearbyAttractions': [
          {
            'name': 'Tiger Point',
            'distance': 2.5,
            'imageUrl':
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
          },
          {
            'name': 'Duke\'s Nose',
            'distance': 4.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
          },
          {
            'name': 'Khandala Mountains',
            'distance': 10.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
          },
        ],
        'policies': {
          'checkInPolicy': 'Check-in from 2:00 PM onwards',
          'checkOutPolicy': 'Check-out before 11:00 AM',
          'cancellationPolicy':
              'Free cancellation up to 7 days before check-in',
          'houseRules': 'No smoking, no parties, no loud noise after 10 PM',
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      };

      final docRef =
          await _firestore.collection('properties').add(testProperty);
      print('✅ Test property created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating test property: $e');
      return null;
    }
  }

  /// Creates multiple test properties at once
  static Future<List<String>> createMultipleTestProperties() async {
    final properties = [
      {
        'name': 'Hill View Farmhouse',
        'city': 'Lonavala',
        'pricePerNight': 5000.0,
      },
      {
        'name': 'Riverside Villa',
        'city': 'Karjat',
        'pricePerNight': 4500.0,
      },
      {
        'name': 'Mountain Cottage',
        'city': 'Khandala',
        'pricePerNight': 6000.0,
      },
      {
        'name': 'Garden Stay',
        'city': 'Lonavala',
        'pricePerNight': 3500.0,
      },
      {
        'name': 'Peaceful Retreat',
        'city': 'Pune',
        'pricePerNight': 4000.0,
      },
    ];

    final ids = <String>[];
    for (var prop in properties) {
      final id = await createTestProperty(
        propertyName: prop['name'] as String,
        city: prop['city'] as String,
      );
      if (id != null) ids.add(id);
    }

    print('✅ Created ${ids.length} test properties');
    return ids;
  }

  /// Deletes all test properties (for cleanup)
  static Future<void> deleteAllTestProperties() async {
    try {
      final snapshot =
          await _firestore.collection('properties').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Cleaned up test properties');
    } catch (e) {
      print('❌ Error deleting test properties: $e');
    }
  }

  /// Get all property IDs (useful for testing)
  static Future<List<String>> getAllPropertyIds() async {
    try {
      final snapshot =
          await _firestore.collection('properties').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error fetching property IDs: $e');
      return [];
    }
  }

  /// Print all properties in Firestore (for debugging)
  static Future<void> printAllProperties() async {
    try {
      final snapshot =
          await _firestore.collection('properties').get();
      print('\n=== All Properties ===');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('ID: ${doc.id}');
        print('Name: ${data['name']}');
        print('City: ${data['city']}');
        print('---');
      }
      print('Total: ${snapshot.docs.length} properties\n');
    } catch (e) {
      print('❌ Error printing properties: $e');
    }
  }
}
