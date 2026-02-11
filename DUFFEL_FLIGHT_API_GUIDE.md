# Duffel Flight Booking - Flutter Example

A complete Flutter example demonstrating how to integrate with the Duffel API for flight search and booking in the sandbox environment.

## Features

- ✅ **Flight Search** - Search flights between airports with date range
- ✅ **Results Display** - Beautiful ListView of available flight offers
- ✅ **Offer Selection** - Select from multiple flight offers
- ✅ **Order Creation** - Create test orders with passenger details
- ✅ **Environment Variables** - Secure token management via `.env`
- ✅ **Error Handling** - Comprehensive error messages and validation
- ✅ **Loading States** - Visual feedback during API calls
- ✅ **Polling** - Smart polling for search results (up to 30 seconds)

## Project Structure

```
lib/
├── services/
│   └── duffel_service.dart          # Duffel API client with models
├── screens/
│   ├── flight_search_screen.dart    # Flight search UI
│   └── order_creation_screen.dart   # Passenger info & order creation
```

## Setup Instructions

### 1. Get Duffel Access Token

1. Go to [Duffel Sandbox](https://app.sandbox.duffel.com)
2. Sign up or log in
3. Navigate to Settings → API
4. Copy your access token

### 2. Install Dependencies

```bash
flutter pub get
```

Or add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
```

### 3. Create `.env` File

Create a `.env` file in the project root:

```
DUFFEL_ACCESS_TOKEN=your_sandbox_token_here
```

### 4. Update Main App

Add the FlightSearchScreen to your main.dart:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skybase/screens/flight_search_screen.dart';

void main() async {
  await dotenv.load(); // Load .env file
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FlightSearchScreen(),
    );
  }
}
```

### 5. Run the App

```bash
flutter run
```

## Usage Guide

### Flight Search

1. **Enter Search Criteria:**
   - Departure Airport (IATA code, e.g., LAX)
   - Arrival Airport (IATA code, e.g., JFK)
   - Departure Date (pick from calendar)
   - Return Date (optional for round trips)
   - Number of Passengers

2. **Click "Search Flights"**
   - API creates a search session
   - System polls for results (up to 30 seconds)
   - Results display as cards with pricing

3. **Select an Offer**
   - Click "Select & Continue"
   - Navigate to Order Creation screen

### Order Creation

1. **Fill Passenger Information:**
   - Title (Mr, Ms, Mrs, Dr)
   - First Name
   - Last Name
   - Email
   - Phone Number
   - Date of Birth
   - Gender

2. **Enter Contact Information:**
   - Contact Email
   - Contact Phone

3. **Click "Create Order"**
   - Order is created in Duffel sandbox
   - Success confirmation with Order ID
   - Display order details

## File Descriptions

### `duffel_service.dart`

**DuffelService Class:**
- `searchFlights()` - Initiates a flight search session
- `getSearchResults()` - Fetches offers from a search session
- `createOrder()` - Creates an order from a selected offer
- `getOrder()` - Retrieves order details

**Models:**
- `SearchFlightsResponse` - Search session details
- `Offer` - Flight offer with price and routing
- `Slice` - Flight segment (outbound/return)
- `Segment` - Individual flight leg
- `Airline` - Airline information
- `Airport` - Airport information
- `PassengerData` - Passenger details for booking
- `OrderResponse` - Created order confirmation

### `flight_search_screen.dart`

**Main Features:**
- Search form with date pickers
- Flight results ListView
- Polling mechanism for search results
- Error handling and validation
- Visual feedback with loading states

**OfferCard Widget:**
- Displays flight offer details
- Shows pricing and routing
- Provides selection button

### `order_creation_screen.dart`

**Main Features:**
- Passenger information form
- Contact information form
- Date picker for date of birth
- Dropdown selections for title and gender
- Order creation with validation
- Success confirmation screen

**Order Confirmation:**
- Displays created order ID
- Shows order details
- Shows original flight details

## API Endpoints Used

```
POST https://api.duffel.com/air/search_sessions
  └─ Create flight search session

GET https://api.duffel.com/air/search_sessions/{id}/offers
  └─ Retrieve offers from search

POST https://api.duffel.com/orders
  └─ Create booking order

GET https://api.duffel.com/orders/{id}
  └─ Get order details
```

## Data Format Examples

### Search Flights Request

```json
{
  "data": {
    "slices": [
      {
        "origin_airport_iata": "LAX",
        "destination_airport_iata": "JFK",
        "departure_date": "2026-02-15"
      }
    ],
    "passengers": [
      { "type": "adult" }
    ],
    "cabin_class": "economy"
  }
}
```

### Create Order Request

```json
{
  "data": {
    "selected_offers": ["offer_123..."],
    "passengers": [
      {
        "id": "passenger_1",
        "title": "Mr",
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com",
        "phone_number": "+1234567890",
        "born_at": "1990-01-15",
        "gender": "male"
      }
    ],
    "type": "instant",
    "contact": {
      "email": "john@example.com",
      "phone_number": "+1234567890"
    }
  }
}
```

## Testing in Sandbox

1. **Use Sandbox Credentials:**
   - The API works with sandbox access token
   - No real payments or bookings are made
   - Perfect for testing and development

2. **Test Data:**
   - Use any IATA airport codes
   - Search future dates (30+ days out recommended)
   - Both one-way and round-trip supported

3. **Common IATA Codes for Testing:**
   - LAX (Los Angeles)
   - JFK (New York)
   - LHR (London)
   - CDG (Paris)
   - SFO (San Francisco)
   - ORD (Chicago)

## Error Handling

The app handles various errors:

- **Missing Fields** - Validation errors shown inline
- **API Errors** - Error messages displayed with context
- **Network Errors** - Caught with timeout handling
- **Parsing Errors** - Graceful fallbacks for missing data

## Polling Mechanism

The search results use an intelligent polling system:

1. Creates search session (returns session ID)
2. Polls every 1 second for results
3. Stops when results found or 30 seconds elapsed
4. Handles empty results gracefully

```dart
Future<void> _pollForOffers(String sessionId) async {
  int attempts = 0;
  const maxAttempts = 30;

  while (attempts < maxAttempts) {
    try {
      final offers = await _duffelService.getSearchResults(sessionId);
      if (offers.isNotEmpty) {
        setState(() => _offers = offers);
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    } catch (e) {
      attempts++;
    }
  }
}
```

## Customization

### Change Cabin Class

In `duffel_service.dart`:
```dart
'cabin_class': 'premium_economy', // or 'business', 'first'
```

### Add More Passenger Types

In `searchFlights()`:
```dart
'passengers': [
  {'type': 'adult'},
  {'type': 'child', 'age': 8},
  {'type': 'infant', 'age': 2},
]
```

### Extend Models

Add more fields to models as needed:
```dart
class Offer {
  final String id;
  final double totalAmount;
  // Add more fields...
}
```

## Security Notes

- ⚠️ **Never commit `.env` file** - Add to `.gitignore`
- ⚠️ **Never hardcode tokens** - Always use environment variables
- ⚠️ **Use HTTPS only** - Duffel API uses HTTPS
- ⚠️ **Validate user input** - Server-side validation recommended

## Troubleshooting

### "No results found" Error

- Dates may be in the past
- Airport codes might be incorrect
- Try dates 30+ days in future
- Increase polling timeout in code

### "Undefined name 'dotenv'"

- Run `flutter pub get`
- Check `flutter_dotenv` is in pubspec.yaml
- Ensure `.env` file exists in project root

### Token Authorization Errors

- Verify token in `.env` file is correct
- Check token hasn't expired
- Try regenerating token from Duffel dashboard

### Empty Search Results

- Valid IATA codes but no flights available
- Try different date range
- Check return date is after departure date

## Next Steps

1. **Add Payment Integration** - Integrate payment gateway
2. **Implement Seat Selection** - Let users pick seats
3. **Add Itinerary Details** - Show full flight details
4. **FCM Notifications** - Booking confirmations
5. **Firebase Integration** - Store bookings in Firestore
6. **Real Payment** - Transition to production Duffel API

## Resources

- [Duffel API Documentation](https://duffel.com/docs)
- [Duffel Sandbox](https://app.sandbox.duffel.com)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Flutter Dotenv Package](https://pub.dev/packages/flutter_dotenv)

## Support

For issues or questions:
1. Check Duffel API documentation
2. Review error messages in console
3. Verify token and credentials
4. Test with different search parameters

---

**Version:** 1.0.0  
**Last Updated:** February 11, 2026  
**Status:** Production Ready ✅
