// Duffel API Examples - Reference Implementation
// Copy and paste snippets as needed

import 'package:skybase/services/duffel_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// EXAMPLE 1: Basic Flight Search
// ============================================

Future<void> exampleBasicSearch() async {
  final duffelService = DuffelService();
  
  try {
    // Search for flights
    final searchResponse = await duffelService.searchFlights(
      departureAirportIata: 'LAX',
      arrivalAirportIata: 'JFK',
      departureDate: '2026-02-25',
      returnDate: '', // Empty for one-way
      passengers: 1,
    );

    print('Search Session ID: ${searchResponse.id}');
    
    // Poll for results (optional - do it manually)
    await Future.delayed(Duration(seconds: 2));
    
    final offers = await duffelService.getSearchResults(searchResponse.id);
    
    print('Found ${offers.length} offers');
    for (var offer in offers) {
      print('${offer.displayPrice} - ${offer.departureInfo}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// ============================================
// EXAMPLE 2: Round-Trip Search with Multiple Passengers
// ============================================

Future<void> exampleRoundTripSearch() async {
  final duffelService = DuffelService();
  
  try {
    final searchResponse = await duffelService.searchFlights(
      departureAirportIata: 'SFO',
      arrivalAirportIata: 'LHR',
      departureDate: '2026-03-15',
      returnDate: '2026-03-22', // Return date specified
      passengers: 2, // 2 passengers
    );

    print('Round-trip search created: ${searchResponse.id}');
    
    // Get results
    final offers = await duffelService.getSearchResults(searchResponse.id);
    
    if (offers.isNotEmpty) {
      // Show details of first offer
      final firstOffer = offers.first;
      print('Best price: ${firstOffer.displayPrice}');
      print('Slices: ${firstOffer.slices.length}'); // Should be 2 for round-trip
    }
  } catch (e) {
    print('Error: $e');
  }
}

// ============================================
// EXAMPLE 3: Create Order from Selected Offer
// ============================================

Future<void> exampleCreateOrder() async {
  final duffelService = DuffelService();
  
  try {
    // First, search for flights (shortened for brevity)
    final searchResponse = await duffelService.searchFlights(
      departureAirportIata: 'LAX',
      arrivalAirportIata: 'JFK',
      departureDate: '2026-02-25',
      returnDate: '',
      passengers: 1,
    );

    // Get offers
    final offers = await duffelService.getSearchResults(searchResponse.id);
    
    if (offers.isEmpty) {
      print('No offers found');
      return;
    }

    // Create order from first offer
    final offer = offers.first;
    
    final passengerData = PassengerData(
      title: 'Mr',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phoneNumber: '+1-800-123-4567',
      dateOfBirth: '1990-05-15',
      gender: 'male',
    );

    final order = await duffelService.createOrder(
      offerId: offer.id,
      passengerData: passengerData,
      contactEmail: 'john@example.com',
      contactPhoneNumber: '+1-800-123-4567',
    );

    print('✅ Order Created!');
    print('Order ID: ${order.id}');
    print('Total: ${order.totalCurrency} ${order.totalAmount}');
    print('Status: ${order.status}');
  } catch (e) {
    print('Error creating order: $e');
  }
}

// ============================================
// EXAMPLE 4: Save Order to Firestore
// ============================================

Future<void> exampleSaveOrderToFirestore(
  String userId,
  Offer selectedOffer,
  OrderResponse createdOrder,
) async {
  try {
    await FirebaseFirestore.instance
        .collection('flight_bookings')
        .doc(createdOrder.id)
        .set({
      'userId': userId,
      'orderId': createdOrder.id,
      'offerId': selectedOffer.id,
      'totalPrice': createdOrder.totalAmount,
      'currency': createdOrder.totalCurrency,
      'status': createdOrder.status,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      // Offer details
      'departure': selectedOffer.slices.isNotEmpty
          ? selectedOffer.slices[0].departureAirportIata
          : '',
      'arrival': selectedOffer.slices.isNotEmpty
          ? selectedOffer.slices[0].arrivalAirportIata
          : '',
      // Store raw offer data for reference
      'offerData': {
        'totalAmount': selectedOffer.totalAmount,
        'currency': selectedOffer.totalCurrency,
        'sliceCount': selectedOffer.slices.length,
      },
    });

    print('✅ Booking saved to Firestore');
  } catch (e) {
    print('Error saving to Firestore: $e');
  }
}

// ============================================
// EXAMPLE 5: Retrieve Booking History from Firestore
// ============================================

Future<List<FlightBooking>> getMyFlightBookings(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('flight_bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FlightBooking.fromJson(doc.data()))
        .toList();
  } catch (e) {
    print('Error fetching bookings: $e');
    return [];
  }
}

// ============================================
// EXAMPLE 6: Stream Flight Bookings in Real-time
// ============================================

Stream<List<FlightBooking>> streamMyFlightBookings(String userId) {
  return FirebaseFirestore.instance
      .collection('flight_bookings')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FlightBooking.fromJson(doc.data()))
          .toList());
}

// ============================================
// EXAMPLE 7: Complete End-to-End Booking Flow
// ============================================

Future<OrderResponse?> completeBookingFlow({
  required String userId,
  required String fromAirport,
  required String toAirport,
  required String departureDate,
  required String returnDate,
  required int passengerCount,
  required PassengerData passengerData,
  required String contactEmail,
  required String contactPhone,
}) async {
  try {
    final duffelService = DuffelService();
    
    // Step 1: Search flights
    print('Step 1: Searching flights...');
    final searchResponse = await duffelService.searchFlights(
      departureAirportIata: fromAirport,
      arrivalAirportIata: toAirport,
      departureDate: departureDate,
      returnDate: returnDate,
      passengers: passengerCount,
    );
    
    // Step 2: Wait for offers
    print('Step 2: Waiting for offers...');
    final offers = await duffelService.getSearchResults(searchResponse.id);
    
    if (offers.isEmpty) {
      print('No offers found');
      return null;
    }
    
    // Step 3: Select best offer (lowest price)
    print('Step 3: Selecting best offer...');
    final bestOffer = offers.reduce((a, b) =>
        a.totalAmount < b.totalAmount ? a : b);
    
    print('Selected offer: ${bestOffer.displayPrice}');
    
    // Step 4: Create order
    print('Step 4: Creating order...');
    final order = await duffelService.createOrder(
      offerId: bestOffer.id,
      passengerData: passengerData,
      contactEmail: contactEmail,
      contactPhoneNumber: contactPhone,
    );
    
    // Step 5: Save to Firestore
    print('Step 5: Saving to Firestore...');
    await exampleSaveOrderToFirestore(userId, bestOffer, order);
    
    print('✅ Booking complete! Order ID: ${order.id}');
    return order;
  } catch (e) {
    print('❌ Error in booking flow: $e');
    return null;
  }
}

// ============================================
// EXAMPLE 8: Send FCM Notification for Booking
// ============================================

Future<void> notifyBookingCreated(
  String userId,
  OrderResponse order,
) async {
  try {
    // Store notification in Firestore
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': userId,
      'type': 'booking_created',
      'title': 'Flight Booking Confirmed',
      'body': 'Your order ${order.id} is confirmed',
      'orderId': order.id,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'data': {
        'orderTotal': order.totalAmount,
        'currency': order.totalCurrency,
      },
    });

    print('✅ Notification recorded');
  } catch (e) {
    print('Error notifying: $e');
  }
}

// ============================================
// EXAMPLE 9: Handle Expired Search Sessions
// ============================================

Future<void> exampleRefreshSearch(String originalSessionId) async {
  final duffelService = DuffelService();
  
  try {
    // If results not found in original session, create new search
    print('Original session: $originalSessionId');
    
    // Create new search with same criteria
    final newSearch = await duffelService.searchFlights(
      departureAirportIata: 'LAX',
      arrivalAirportIata: 'JFK',
      departureDate: '2026-02-25',
      returnDate: '',
      passengers: 1,
    );
    
    print('New session: ${newSearch.id}');
    
    final offers = await duffelService.getSearchResults(newSearch.id);
    print('Found ${offers.length} offers in new search');
  } catch (e) {
    print('Error: $e');
  }
}

// ============================================
// EXAMPLE 10: Validate Passenger Data
// ============================================

bool isValidPassengerData(PassengerData data) {
  // Check names
  if (data.firstName.isEmpty || data.lastName.isEmpty) {
    print('Error: First and last name required');
    return false;
  }
  
  // Check email format
  if (!data.email.contains('@')) {
    print('Error: Valid email required');
    return false;
  }
  
  // Check phone format
  if (data.phoneNumber.length < 10) {
    print('Error: Valid phone number required');
    return false;
  }
  
  // Check date of birth format (YYYY-MM-DD)
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data.dateOfBirth)) {
    print('Error: Date of birth must be YYYY-MM-DD');
    return false;
  }
  
  // Check gender
  if (data.gender != 'male' && data.gender != 'female') {
    print('Error: Gender must be male or female');
    return false;
  }
  
  print('✅ Passenger data is valid');
  return true;
}

// ============================================
// MODEL EXTENSIONS (Firestore Integration)
// ============================================

class FlightBooking {
  final String orderId;
  final String userId;
  final String departure;
  final String arrival;
  final double totalPrice;
  final String currency;
  final String status;
  final DateTime createdAt;

  FlightBooking({
    required this.orderId,
    required this.userId,
    required this.departure,
    required this.arrival,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory FlightBooking.fromJson(Map<String, dynamic> json) {
    return FlightBooking(
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      departure: json['departure'] ?? '',
      arrival: json['arrival'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'userId': userId,
    'departure': departure,
    'arrival': arrival,
    'totalPrice': totalPrice,
    'currency': currency,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ============================================
// USEFUL HELPERS
// ============================================

// Convert DateTime to YYYY-MM-DD format
String formatDateForDuffel(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// Format price with currency
String formatPrice(double amount, String currency) {
  return '$currency ${amount.toStringAsFixed(2)}';
}

// Check if date is in the past
bool isPastDate(String dateString) {
  final date = DateTime.parse(dateString);
  return date.isBefore(DateTime.now());
}

// Get common IATA codes
const Map<String, String> commonAirports = {
  'LAX': 'Los Angeles',
  'JFK': 'New York',
  'LHR': 'London',
  'CDG': 'Paris',
  'SFO': 'San Francisco',
  'ORD': 'Chicago',
  'DXB': 'Dubai',
  'SYD': 'Sydney',
  'NRT': 'Tokyo',
  'SIN': 'Singapore',
};

// ============================================
// EXAMPLE 5: Use offer_requests endpoint (searchOffers)
// ============================================

Future<void> exampleOfferRequestsSearch() async {
  final duffelService = DuffelService();

  try {
    final resp = await duffelService.searchOffers(
      origin: 'LHR',
      destination: 'JFK',
      departureDate: '2026-03-01',
      adults: 1,
    );

    print('Offer Requests response: $resp');

    // If response contains 'data' array with offers, print basics
    final data = resp['data'];
    if (data is List && data.isNotEmpty) {
      print('Found ${data.length} offers in response');
    } else {
      print('No offers in response');
    }
  } catch (e) {
    print('Error when calling searchOffers: $e');
  }
}
