class PropertyModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String category;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final double pricePerNight;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final int minStay;
  final List<String> imageUrls;
  final List<String> highlights;
  final List<String> amenities;
  final Map<String, dynamic> policies;
  final Map<String, dynamic> timings;
  final List<NearbyAttraction> nearbyAttractions;
  final double averageRating;
  final int reviewCount;
  final bool instantBooking;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic>? ownerDetails;

  PropertyModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.pricePerNight,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.minStay,
    required this.imageUrls,
    this.highlights = const [],
    this.amenities = const [],
    this.policies = const {},
    this.timings = const {},
    this.nearbyAttractions = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.instantBooking = false,
    this.isActive = true,
    required this.createdAt,
    this.ownerDetails,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      pricePerNight: (json['pricePerNight'] ?? 0.0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      maxGuests: json['maxGuests'] ?? 0,
      minStay: json['minStay'] ?? 1,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      highlights: List<String>.from(json['highlights'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      policies: json['policies'] ?? {},
      timings: json['timings'] ?? {},
      nearbyAttractions: (json['nearbyAttractions'] as List?)
              ?.map((e) => NearbyAttraction.fromJson(e))
              .toList() ??
          [],
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      instantBooking: json['instantBooking'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      ownerDetails: json['ownerDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'category': category,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerNight': pricePerNight,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'maxGuests': maxGuests,
      'minStay': minStay,
      'imageUrls': imageUrls,
      'highlights': highlights,
      'amenities': amenities,
      'policies': policies,
      'timings': timings,
      'nearbyAttractions': nearbyAttractions.map((e) => e.toJson()).toList(),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'instantBooking': instantBooking,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'ownerDetails': ownerDetails,
    };
  }
}

class NearbyAttraction {
  final String name;
  final double distance;
  final String? imageUrl;
  final String? type;

  NearbyAttraction({
    required this.name,
    required this.distance,
    this.imageUrl,
    this.type,
  });

  factory NearbyAttraction.fromJson(Map<String, dynamic> json) {
    return NearbyAttraction(
      name: json['name'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'imageUrl': imageUrl,
      'type': type,
    };
  }
}
