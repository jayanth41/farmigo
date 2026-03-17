class Offer {
  final String id;
  final String airlineName;
  final String airlineLogo;

  final String origin;
  final String destination;

  final String departureTime;
  final String arrivalTime;

  final String duration;
  final int durationMinutes;

  final String stopsLabel;

  final double price;
  final String currency;

  Offer({
    required this.id,
    required this.airlineName,
    required this.airlineLogo,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.durationMinutes,
    required this.stopsLabel,
    required this.price,
    required this.currency,
  });

  String get displayPrice {
    if (currency == "INR") {
      return "₹${price.toStringAsFixed(0)}";
    }
    return "$currency ${price.toStringAsFixed(0)}";
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    final slices = json["slices"] ?? [];
    final slice = slices.isNotEmpty ? slices[0] : null;

    final segments = slice?["segments"] ?? [];
    final segment = segments.isNotEmpty ? segments[0] : null;

    final airline = segment?["operating_carrier"] ?? {};

    final duration = slice?["duration"] ?? "PT0H";

    int durationMinutes = 0;

    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
    final match = regex.firstMatch(duration);

    if (match != null) {
      final h = int.tryParse(match.group(1) ?? "0") ?? 0;
      final m = int.tryParse(match.group(2) ?? "0") ?? 0;
      durationMinutes = h * 60 + m;
    }

    String formattedDuration = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";

    final stops = segments.length - 1;

    return Offer(
      id: json["id"] ?? "",
      airlineName: airline["name"] ?? "Airline",
      airlineLogo: airline["logo_symbol_url"] ?? "",

      origin: segment?["origin"]?["iata_code"] ?? "",
      destination: segment?["destination"]?["iata_code"] ?? "",

      departureTime: segment?["departing_at"]?.substring(11, 16) ?? "",
      arrivalTime: segment?["arriving_at"]?.substring(11, 16) ?? "",

      duration: formattedDuration,
      durationMinutes: durationMinutes,

      stopsLabel: stops == 0 ? "Non-stop" : "$stops stop",

      price: double.tryParse(json["total_amount"] ?? "0") ?? 0,
      currency: json["total_currency"] ?? "USD",
    );
  }
}