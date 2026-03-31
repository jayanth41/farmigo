import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;
import 'package:intl/intl.dart';
import '../models/offer.dart';

class DuffelService {
  static const String baseUrl = 'https://api.duffel.com';
  String get accessToken {
    // Prevent crash if dotenv has not been initialized yet
    if (!env.dotenv.isInitialized) {
      throw Exception(
        'Environment variables not initialized. Make sure dotenv.load() is called in main() before using DuffelService.',
      );
    }

    final token = env.dotenv.env['DUFFEL_ACCESS_TOKEN'];

    if (token == null || token.isEmpty) {
      throw Exception(
        'DUFFEL_ACCESS_TOKEN is missing in assets/.env file.',
      );
    }

    return token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
    'Duffel-Version': 'v2',
  };

  /// Search flights between two airports
  Future<SearchFlightsResponse> searchFlights({
    required String departureAirportIata,
    required String arrivalAirportIata,
    required String departureDate,
    required String returnDate,
    required int passengers,
  }) async {
    try {
      final body = {
        'data': {
          'slices': [
            {
              'origin': departureAirportIata,
              'destination': arrivalAirportIata,
              'departure_date': departureDate,
            },
            if (returnDate.isNotEmpty)
              {
                'origin': arrivalAirportIata,
                'destination': departureAirportIata,
                'departure_date': returnDate,
              },
          ],
          'passengers': List.generate(
            passengers,
            (_) => {
              'type': 'adult',
            },
          ),
          'cabin_class': 'economy',
        },
      };

      final response = await http.post(
        Uri.parse('$baseUrl/air/offer_requests'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        return SearchFlightsResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to search flights: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching flights: $e');
    }
  }

  /// ⚠️ Duffel v2 already returns offers inside offer_requests response
  /// This method is deprecated and should not be used
  Future<List<Offer>> getOffers(String requestId) async {
    throw Exception(
      'getOffers is deprecated in Duffel v2. Offers are already included in the searchOffers response.',
    );
  }

  /// Create an order from an offer
  Future<OrderResponse> createOrder({
    required String offerId,
    required PassengerData passengerData,
    required String contactEmail,
    required String contactPhoneNumber,
  }) async {
    try {
      final body = {
        'data': {
          'type': 'instant',
          'selected_offers': [offerId],
          'passengers': [
            {
              if (passengerData.passengerId != null && passengerData.passengerId!.isNotEmpty)
                'id': passengerData.passengerId,
              'type': 'adult',
              'title': passengerData.title,
              'given_name': passengerData.firstName.trim(),
              'family_name': passengerData.lastName.trim(),
              'born_on': passengerData.dateOfBirth,
              'gender': passengerData.gender == 'male' ? 'm' : 'f',
              'email': passengerData.email,
              'phone_number': passengerData.phoneNumber,
            }
          ],
          'payments': [
            {
              'type': 'balance',
              'currency': 'GBP',
              'amount': passengerData.amount,
            }
          ],
          'contacts': [
            {
              'email_address': contactEmail,
              'phone_number': contactPhoneNumber,
            }
          ],
        }
      };

      print('📦 CREATE ORDER REQUEST: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/air/orders'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('📩 CREATE ORDER RESPONSE: ${response.body}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return OrderResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Duffel Order Error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  /// Get order details
  Future<OrderResponse> getOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/air/orders/$orderId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return OrderResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to get order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting order: $e');
    }
  }

  /// Create an offer request using the *offer_requests* endpoint
  /// Body: {"slices": [...], "passengers": [...]}
  /// Returns the parsed JSON response from Duffel
  Future<Map<String, dynamic>> searchOffers({
    required String origin,
    required String destination,
    required String departureDate, // YYYY-MM-DD
    int adults = 1,
  }) async {
    if (accessToken.isEmpty) {
      throw Exception('Duffel access token not configured (DUFFEL_ACCESS_TOKEN)');
    }

    final url = Uri.parse('$baseUrl/air/offer_requests');

    final body = {
      'data': {
        'slices': [
          {
            'origin': origin,
            'destination': destination,
            'departure_date': departureDate,
          }
        ],
        'passengers': List.generate(adults, (_) => {'type': 'adult'}),
        'cabin_class': 'economy',
      }
    };

    print('🛫 Duffel search request payload: ${jsonEncode(body)}');
    print('🧾 Duffel headers => $_headers');

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      print('🟢 REQUEST ID => ${decoded['data']?['id']}');

      final offers = decoded['data']?['offers'] ?? [];
      print('🟢 OFFERS COUNT => ${offers.length}');
      print('🟢 DUFFEL RESPONSE => $decoded');

      return decoded as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw DuffelApiException(401, 'Unauthorized: Invalid Duffel token');
    }

    String message = response.body;
    try {
      final parsed = jsonDecode(response.body);
      message = parsed.toString();
    } catch (_) {}

    throw DuffelApiException(response.statusCode, message);
  }
}


class DuffelApiException implements Exception {
  final int statusCode;
  final String message;
  DuffelApiException(this.statusCode, this.message);

  @override
  String toString() => 'DuffelApiException($statusCode): $message';
}

// Models

class SearchFlightsResponse {
  final String id;
  final String type;
  final String createdAt;

  SearchFlightsResponse({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  factory SearchFlightsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return SearchFlightsResponse(
      id: data['id'] ?? '',
      type: data['type'] ?? 'search_session',
      createdAt: data['created_at'] ?? '',
    );
  }
}

class DuffelOffer {
  final String id;
  final double totalAmount;
  final String totalCurrency;
  final List<Slice> slices;
  final List<Airline> airlines;
  final List<Airport> airports;

  DuffelOffer({
    required this.id,
    required this.totalAmount,
    required this.totalCurrency,
    required this.slices,
    required this.airlines,
    required this.airports,
  });

  factory DuffelOffer.fromJson(Map<String, dynamic> json) {
    final baseData = json['attributes'] ?? json;
    
    List<Slice> slices = [];
    final rawSlices = baseData['slices'];

    if (rawSlices is List) {
      slices = rawSlices
          .whereType<Map<String, dynamic>>() // prevent type crash
          .map((s) => Slice.fromJson(s))
          .toList();
    }

    List<Airline> airlines = [];
    final rawAirlines = baseData['airlines'];

    if (rawAirlines is List) {
      airlines = rawAirlines
          .whereType<Map<String, dynamic>>()
          .map((a) => Airline.fromJson(a))
          .toList();
    }

    List<Airport> airports = [];
    final rawAirports = baseData['airports'];

    if (rawAirports is List) {
      airports = rawAirports
          .whereType<Map<String, dynamic>>()
          .map((a) => Airport.fromJson(a))
          .toList();
    }

    return DuffelOffer(
      id: json['id'] ?? '',
      totalAmount: double.tryParse(
        baseData['total_amount']?.toString() ?? '0',
      ) ?? 0,
      totalCurrency: baseData['total_currency'] ?? 'USD',
      slices: slices,
      airlines: airlines,
      airports: airports,
    );
  }

  String get currencySymbol {
    switch (totalCurrency) {
      case 'INR':
        return '₹';
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return totalCurrency;
    }
  }

  /// Converts price to INR for Indian users (approx rates)
  double get priceInINR {
    switch (totalCurrency) {
      case 'INR':
        return totalAmount;
      case 'GBP':
        return totalAmount * 105;
      case 'USD':
        return totalAmount * 83;
      case 'EUR':
        return totalAmount * 90;
      default:
        return totalAmount;
    }
  }

  /// Display price formatted for UI (INR preferred)
  String get displayPrice {
    final price = priceInINR;
    final formatter = NumberFormat('#,##,###');
    return '₹${formatter.format(price.round())}';
  }
  
  String get departureInfo {
    if (slices.isEmpty) return 'N/A';
    return slices[0].toString();
  }

  /// Origin airport (first slice)
  String get origin {
    if (slices.isEmpty) return '--';
    return slices.first.departureAirportIata;
  }

  /// Destination airport (last slice)
  String get destination {
    if (slices.isEmpty) return '--';
    return slices.first.arrivalAirportIata;
  }

  /// Departure time (HH:MM)
  String get departureTime {
    if (slices.isEmpty || slices.first.departureAt.isEmpty) return '--';
    final t = slices.first.departureAt;
    return _formatTime(t);
  }

  /// Arrival time (HH:MM)
  String get arrivalTime {
    if (slices.isEmpty || slices.first.arrivalAt.isEmpty) return '--';
    final t = slices.first.arrivalAt;
    return _formatTime(t);
  }

  /// Duration estimate
  String get duration {
    if (slices.isEmpty) return '--';

    final segs = slices.first.segments;
    if (segs.isEmpty) return '--';

    final dep = DateTime.tryParse(segs.first.departureAt);
    final arr = DateTime.tryParse(segs.last.arrivalAt);

    if (dep == null || arr == null) return '--';

    final diff = arr.difference(dep);

    final h = diff.inHours;
    final m = diff.inMinutes % 60;

    final stops = segs.length - 1;

    if (stops == 0) {
      return '${h}h ${m}m • Non-stop';
    } else {
      return '${h}h ${m}m • $stops stop';
    }
  }

  /// Duration in minutes (used for sorting / fastest filter)
  int get durationMinutes {
    if (slices.isEmpty) return 0;

    final segs = slices.first.segments;
    if (segs.isEmpty) return 0;

    final dep = DateTime.tryParse(segs.first.departureAt);
    final arr = DateTime.tryParse(segs.last.arrivalAt);

    if (dep == null || arr == null) return 0;

    return arr.difference(dep).inMinutes;
  }

  /// Airline name if available
  String get airlineName {
    if (airlines.isNotEmpty) return airlines.first.name;

    if (slices.isNotEmpty && slices.first.segments.isNotEmpty) {
      final code = slices.first.segments.first.operatingCarrierCode;
      if (code.isNotEmpty) return code;
    }

    return 'Airline';
  }

  /// Airline IATA code
  String get airlineCode {
    if (airlines.isEmpty) return '';
    return airlines.first.iataCode;
  }

  /// Flight number (from first segment)
  String get flightNumber {
    if (slices.isEmpty || slices.first.segments.isEmpty) return '';
    final seg = slices.first.segments.first;
    if (seg.operatingCarrierCode.isEmpty) return '';

    return '${seg.operatingCarrierCode}${seg.id.isNotEmpty ? '' : ''}';
  }

  /// Number of stops
  int get stops {
    if (slices.isEmpty) return 0;
    final segs = slices.first.segments;
    if (segs.isEmpty) return 0;
    return segs.length - 1;
  }

  /// True if flight has no layovers
  bool get isNonStop {
    return stops == 0;
  }

  /// Stops label for UI
  String get stopsLabel {
    if (stops == 0) return 'Non-stop';
    if (stops == 1) return '1 stop';
    return '$stops stops';
  }

  /// Layover time between first and second segment
  String get layoverInfo {
    if (slices.isEmpty) return '';

    final segs = slices.first.segments;
    if (segs.length < 2) return '';

    final arr = DateTime.tryParse(segs.first.arrivalAt);
    final dep = DateTime.tryParse(segs[1].departureAt);

    if (arr == null || dep == null) return '';

    final diff = dep.difference(arr);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;

    return '${h}h ${m}m layover';
  }

  /// Airline logo URL (uses IATA code)
  /// Example source: https://content.airhex.com/content/logos/airlines_<IATA>_200_200_s.png
  String get airlineLogo {
    String code = airlineCode;

    if (code.isEmpty &&
        slices.isNotEmpty &&
        slices.first.segments.isNotEmpty) {
      code = slices.first.segments.first.operatingCarrierCode;
    }

    if (code.isEmpty) return '';

    return 'https://content.airhex.com/content/logos/airlines_${code}_200_200_s.png';
  }

  /// Helper to convert ISO time to HH:MM
  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';

    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }
}

class Slice {
  final String id;
  final String departureAirportIata;
  final String arrivalAirportIata;
  final String departureAt;
  final String arrivalAt;
  final List<Segment> segments;

  Slice({
    required this.id,
    required this.departureAirportIata,
    required this.arrivalAirportIata,
    required this.departureAt,
    required this.arrivalAt,
    required this.segments,
  });

  factory Slice.fromJson(Map<String, dynamic> json) {
    List<Segment> segments = [];
    if (json['segments'] != null) {
      segments = (json['segments'] as List<dynamic>)
          .map((s) => Segment.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    String origin = '';
    String destination = '';
    String departureAt = '';
    String arrivalAt = '';

    if (segments.isNotEmpty) {
      origin = segments.first.departureAirportIata;
      destination = segments.last.arrivalAirportIata;
      departureAt = segments.first.departureAt;
      arrivalAt = segments.last.arrivalAt;
    }

    return Slice(
      id: json['id'] ?? '',
      departureAirportIata: origin,
      arrivalAirportIata: destination,
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      segments: segments,
    );
  }

  @override
  String toString() {
    if (segments.isEmpty) return 'No segments';
    final seg = segments.first;
    return '${seg.departureAirportIata} → ${seg.arrivalAirportIata}';
  }
}

class Segment {
  final String id;
  final String departureAirportIata;
  final String arrivalAirportIata;
  final String departureAt;
  final String arrivalAt;
  final String operatingCarrierCode;

  Segment({
    required this.id,
    required this.departureAirportIata,
    required this.arrivalAirportIata,
    required this.departureAt,
    required this.arrivalAt,
    required this.operatingCarrierCode,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    String origin = '';
    String destination = '';

    if (json['origin'] is Map) {
      origin = json['origin']['iata_code'] ?? '';
    } else {
      origin = json['origin_airport_iata'] ?? '';
    }

    if (json['destination'] is Map) {
      destination = json['destination']['iata_code'] ?? '';
    } else {
      destination = json['destination_airport_iata'] ?? '';
    }

    String carrier = '';
    if (json['operating_carrier'] is Map) {
      carrier = json['operating_carrier']['iata_code'] ?? '';
    } else {
      carrier = json['operating_carrier_code'] ?? '';
    }

    return Segment(
      id: json['id'] ?? '',
      departureAirportIata: origin,
      arrivalAirportIata: destination,
      departureAt: json['departing_at'] ?? json['departure_at'] ?? '',
      arrivalAt: json['arriving_at'] ?? json['arrival_at'] ?? '',
      operatingCarrierCode: carrier,
    );
  }
}

class Airline {
  final String iataCode;
  final String name;

  Airline({required this.iataCode, required this.name});

  factory Airline.fromJson(Map<String, dynamic> json) {
    return Airline(
      iataCode: json['iata_code'] ?? '',
      name: json['name'] ?? 'Unknown Airline',
    );
  }
}

class Airport {
  final String iataCode;
  final String name;
  final String city;

  Airport({
    required this.iataCode,
    required this.name,
    required this.city,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      iataCode: json['iata_code'] ?? '',
      name: json['name'] ?? '',
      city: json['city_name'] ?? '',
    );
  }
}

class PassengerData {
  final String? passengerId; // optional to avoid breaking existing calls
  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth; // Format: YYYY-MM-DD
  final String gender; // male or female
  final String amount;

  PassengerData({
    this.passengerId, // NOT required anymore
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.amount,
  });
}

class OrderResponse {
  final String id;
  final String type;
  final double totalAmount;
  final String totalCurrency;
  final String createdAt;
  final String status;

  OrderResponse({
    required this.id,
    required this.type,
    required this.totalAmount,
    required this.totalCurrency,
    required this.createdAt,
    required this.status,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final attributes = data['attributes'] ?? data;

    return OrderResponse(
      id: data['id'] ?? '',
      type: data['type'] ?? 'order',
      totalAmount: double.tryParse(
        attributes['total_amount']?.toString() ?? '0',
      ) ?? 0,
      totalCurrency: attributes['total_currency'] ?? 'USD',
      createdAt: attributes['created_at'] ?? '',
      status: attributes['status'] ?? 'pending',
    );
  }
}
