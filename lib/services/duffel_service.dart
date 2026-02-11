import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DuffelService {
  static const String baseUrl = 'https://api.duffel.com';
  late String accessToken;

  DuffelService() {
    accessToken = dotenv.env['DUFFEL_ACCESS_TOKEN'] ?? '';
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
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
              'origin_airport_iata': departureAirportIata,
              'destination_airport_iata': arrivalAirportIata,
              'departure_date': departureDate,
            },
            if (returnDate.isNotEmpty)
              {
                'origin_airport_iata': arrivalAirportIata,
                'destination_airport_iata': departureAirportIata,
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
        Uri.parse('$baseUrl/air/search_sessions'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return SearchFlightsResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to search flights: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching flights: $e');
    }
  }

  /// Get search results for a session ID
  Future<List<Offer>> getSearchResults(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/air/search_sessions/$sessionId/offers'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final offersJson = jsonResponse['data'] as List<dynamic>? ?? [];
        
        return offersJson
            .map((offer) => Offer.fromJson(offer as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get search results: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting search results: $e');
    }
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
          'selected_offers': [offerId],
          'passengers': [
            {
              'id': 'passenger_1',
              'title': passengerData.title,
              'first_name': passengerData.firstName,
              'last_name': passengerData.lastName,
              'email': passengerData.email,
              'phone_number': passengerData.phoneNumber,
              'born_at': passengerData.dateOfBirth, // Format: YYYY-MM-DD
              'gender': passengerData.gender,
            }
          ],
          'type': 'instant',
          'contact': {
            'email': contactEmail,
            'phone_number': contactPhoneNumber,
          },
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return OrderResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  /// Get order details
  Future<OrderResponse> getOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
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
      'slices': [
        {
          'origin': origin,
          'destination': destination,
          'departure_date': departureDate,
        }
      ],
      'passengers': List.generate(adults, (_) => {'type': 'adult'}),
      'payment': null,
    };

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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

class Offer {
  final String id;
  final double totalAmount;
  final String totalCurrency;
  final List<Slice> slices;
  final List<Airline> airlines;
  final List<Airport> airports;

  Offer({
    required this.id,
    required this.totalAmount,
    required this.totalCurrency,
    required this.slices,
    required this.airlines,
    required this.airports,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final baseData = json['attributes'] ?? json;
    
    List<Slice> slices = [];
    if (baseData['slices'] != null) {
      slices = (baseData['slices'] as List<dynamic>)
          .map((s) => Slice.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    List<Airline> airlines = [];
    if (baseData['airlines'] != null) {
      airlines = (baseData['airlines'] as List<dynamic>)
          .map((a) => Airline.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<Airport> airports = [];
    if (baseData['airports'] != null) {
      airports = (baseData['airports'] as List<dynamic>)
          .map((a) => Airport.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return Offer(
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

  String get displayPrice => '$totalCurrency $totalAmount';
  
  String get departureInfo {
    if (slices.isEmpty) return 'N/A';
    return slices[0].toString();
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

    return Slice(
      id: json['id'] ?? '',
      departureAirportIata: json['origin_airport_iata'] ?? '',
      arrivalAirportIata: json['destination_airport_iata'] ?? '',
      departureAt: json['departure_at'] ?? '',
      arrivalAt: json['arrival_at'] ?? '',
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
    return Segment(
      id: json['id'] ?? '',
      departureAirportIata: json['origin_airport_iata'] ?? '',
      arrivalAirportIata: json['destination_airport_iata'] ?? '',
      departureAt: json['departing_at'] ?? '',
      arrivalAt: json['arriving_at'] ?? '',
      operatingCarrierCode: json['operating_carrier_code'] ?? '',
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
  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth; // Format: YYYY-MM-DD
  final String gender; // male or female

  PassengerData({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
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
