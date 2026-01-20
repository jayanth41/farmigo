class CarRental {
  final String id;
  final String name;
  final String type; // e.g., Sedan, SUV
  final String location; // city/state
  final double rating; // 0.0 - 5.0
  final int reviews;
  final List<String> features; // e.g., ['AC', 'Driver', 'Fuel Included']
  final int pricePerDay; // in INR
  final String imageUrl;
  final int? discountPercent;
  final bool isFavorite;

  const CarRental({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.features,
    required this.pricePerDay,
    required this.imageUrl,
    this.discountPercent,
    this.isFavorite = false,
  });
}
