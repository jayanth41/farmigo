import 'package:intl/intl.dart';

class Offer {
  final String id;
  final String airlineName;
  final String airlineLogo;
  final String flightNumber;

  final String origin;
  final String destination;

  final String departureTime;
  final String arrivalTime;
  final DateTime? departureDateTime;

  final String duration;
  final int durationMinutes;

  final String stopsLabel;

  final double price;
  final String currency;

  /// Number of stops derived from the label
  int get stopsCount {
    if (stopsLabel == "Non-stop") return 0;
    final match = RegExp(r'(\d+)').firstMatch(stopsLabel);
    return match != null ? int.tryParse(match.group(1) ?? "1") ?? 1 : 1;
  }

  /// Short airline code derived from the logo URL when possible
  String get airlineCode {
    if (airlineLogo.contains("airlines_")) {
      final start = airlineLogo.indexOf("airlines_") + 9;
      final end = airlineLogo.indexOf("_200");
      if (start > 0 && end > start) {
        return airlineLogo.substring(start, end).toUpperCase();
      }
    }
    return airlineName.isNotEmpty ? airlineName.substring(0, 2).toUpperCase() : "FL";
  }

  /// Whether the flight is non-stop
  bool get isNonStop => stopsLabel == "Non-stop";

  /// Price converted to INR (approximate conversion for UI ranking)
  double get priceInINR {
    switch (currency) {
      case "INR":
        return price;
      case "GBP":
        return price * 105;
      case "USD":
        return price * 83;
      case "EUR":
        return price * 90;
      default:
        return price;
    }
  }

  /// Best value score (lower is better)
  double get bestValueScore {
    return priceInINR + (durationMinutes * 2);
  }

  /// Timestamp used for sorting by departure time
  int get departureTimestamp {
    return departureDateTime?.millisecondsSinceEpoch ?? 0;
  }

  /// Departure period used for filters
  String get departurePeriod {
    final hour = departureDateTime?.hour ?? 0;

    if (hour >= 6 && hour < 12) return "Morning";
    if (hour >= 12 && hour < 18) return "Afternoon";
    if (hour >= 18 && hour < 24) return "Evening";
    return "Night";
  }

  Offer({
    required this.id,
    required this.airlineName,
    required this.airlineLogo,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDateTime,
    required this.duration,
    required this.durationMinutes,
    required this.stopsLabel,
    required this.price,
    required this.currency,
  });

  String get displayPrice {
    final formatter = NumberFormat('#,##,###');
    return "₹${formatter.format(priceInINR.round())}";
  }

  /// Airline display name for UI (prevents crash if field missing)
  String get airlineDisplay {
    if (airlineName.isNotEmpty) return airlineName;
    if (airlineCode.isNotEmpty) return airlineCode;
    return "Airline";
  }

  static String _safeTime(String? isoTime) {
    if (isoTime == null || isoTime.length < 16) return "";
    return isoTime.substring(11, 16);
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    final slices = json["slices"] is List
        ? List<Map<String, dynamic>>.from(json["slices"])
        : [];
    final slice = slices.isNotEmpty ? slices[0] : null;

    final segments = (slice?["segments"] as List?)
        ?.map((e) => Map<String, dynamic>.from(e))
        .toList() ??
        [];
    final segment = segments.isNotEmpty ? segments[0] : null;

  final airline = segment?["operating_carrier"] is Map
      ? Map<String, dynamic>.from(segment?["operating_carrier"])
      : <String, dynamic>{};
    final flightNumber = segment?["marketing_carrier_flight_number"] ??
        segment?["operating_carrier_flight_number"] ??
        "";

    final carrierCode =
        airline["iata_code"] ??
        segment?["operating_carrier_code"] ??
        "";

    final duration = (slice?["duration"] ?? "PT0H").toString();

    int durationMinutes = 0;

    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
    final match = regex.firstMatch(duration);

    if (match != null) {
      final h = int.tryParse(match.group(1) ?? "0") ?? 0;
      final m = int.tryParse(match.group(2) ?? "0") ?? 0;
      durationMinutes = h * 60 + m;
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    String formattedDuration =
        hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

    final stops = segments.length - 1;

  return Offer(
      id: json["id"] ?? "",
      airlineName: airline["name"] ?? "Airline",
      airlineLogo: airline["logo_symbol_url"] ??
          (carrierCode.isNotEmpty
              ? "https://content.airhex.com/content/logos/airlines_${carrierCode}_200_200_s.png"
              : ""),
      flightNumber: flightNumber,

      origin: segment?["origin"]?["iata_code"]?.toString() ?? "",
      destination: segment?["destination"]?["iata_code"]?.toString() ?? "",

      departureTime: _safeTime(segment?["departing_at"]),
      arrivalTime: _safeTime(segment?["arriving_at"]),
      departureDateTime: DateTime.tryParse(
        segment?["departing_at"]?.toString() ?? "",
      ),

      duration: formattedDuration,
      durationMinutes: durationMinutes,

      stopsLabel: stops == 0
          ? "Non-stop"
          : stops == 1
              ? "1 stop"
              : "$stops stops",

      price: json["total_amount"] is String
          ? double.tryParse(json["total_amount"]) ?? 0
          : (json["total_amount"] is num
              ? (json["total_amount"] as num).toDouble()
              : 0),
      currency: json["total_currency"] is String
          ? json["total_currency"]
          : "USD",
    );
  }
}