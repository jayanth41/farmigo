class FarmhouseModel {
  final String id;
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;
  final List<String> images;
  final String category;
  final String propertyType;
  final double rating;
  final int reviewCount;

  FarmhouseModel({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
    this.images = const [],
    this.category = 'All',
    this.propertyType = 'Farmhouse',
    this.rating = 4.5,
    this.reviewCount = 120,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'price': price,
      'distance': distance,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'propertyType': propertyType,
      'rating': rating,
    };
  }

  // Create from JSON
  factory FarmhouseModel.fromJson(Map<String, dynamic> json) {
    return FarmhouseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      price: (json['price'] as num).toDouble(),
      distance: json['distance'] as String,
      imageUrl: json['imageUrl'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: json['category'] as String? ?? 'All',
      propertyType: json['propertyType'] as String? ?? 'Farmhouse',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 120,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmhouseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}