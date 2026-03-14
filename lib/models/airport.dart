class Airport {
  final String name;
  final String city;
  final String iata;

  Airport({
    required this.name,
    required this.city,
    required this.iata,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      name: json['name'],
      city: json['city'],
      iata: json['iata'],
    );
  }

  @override
  String toString() => "$city ($iata)";
}