class Airport {
  final String name;
  final String city;
  final String iata;

  Airport({
    required this.name,
    required this.city,
    required this.iata,
  });

  /// Display label for UI lists
  String get displayLabel => "$city ($iata)";

  /// Subtitle showing airport name
  String get subtitle => name;

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      name: json['name'],
      city: json['city'],
      iata: json['iata'],
    );
  }

  @override
  String toString() => displayLabel;
}