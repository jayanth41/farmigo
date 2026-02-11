Duffel Service Integration

Overview
- This project includes a Duffel integration in `lib/services/duffel_service.dart`.
- Example UI available at `lib/screens/flight_search_screen.dart` (search_sessions flow) and `lib/screens/duffel_offer_search_screen.dart` (offer_requests flow).

Setup
1. Add your Duffel API token to `.env` as:

   DUFFEL_ACCESS_TOKEN=duffel_live_XXXXXXXXXXXXXXXX

2. Restart the app (`flutter run`) so `flutter_dotenv` loads the `.env` file.

Usage
- Programmatic use:
  final ds = DuffelService();
  final resp = await ds.searchOffers(origin: 'LHR', destination: 'JFK', departureDate: '2026-03-01');

- UI:
  - Navigate to `DuffelOfferSearchScreen` in the app and use the form to search.

Error handling
- `searchOffers` throws `DuffelApiException` with status code and message for non-2xx responses.
- Example: 401 -> Unauthorized, 403 -> Forbidden

Note about tokens
- Use live tokens in production and test tokens for development. Keep your tokens secure.

