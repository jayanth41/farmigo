class FarmhouseModel {
  final String id;
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;
  final double? rating;

  FarmhouseModel({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
    this.rating,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'price': price,
      'distance': distance,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }

  // Create from JSON
  factory FarmhouseModel.fromJson(Map<String, dynamic> json) {
    return FarmhouseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      distance: json['distance'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmhouseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
