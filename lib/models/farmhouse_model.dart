class FarmhouseModel {
  final String id;
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;

  FarmhouseModel({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
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