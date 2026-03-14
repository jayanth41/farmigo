import '../models/airport.dart';

class AirportService {
  static final List<Airport> airports = [
    Airport(name: "Rajiv Gandhi International Airport", city: "Hyderabad", iata: "HYD"),
    Airport(name: "Indira Gandhi International Airport", city: "Delhi", iata: "DEL"),
    Airport(name: "Chhatrapati Shivaji Airport", city: "Mumbai", iata: "BOM"),
    Airport(name: "Kempegowda Airport", city: "Bangalore", iata: "BLR"),
    Airport(name: "Chennai International Airport", city: "Chennai", iata: "MAA"),
  ];

  static List<Airport> search(String query) {
    return airports.where((airport) {
      return airport.city.toLowerCase().contains(query.toLowerCase()) ||
          airport.iata.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Convert user input (city or IATA) to a valid IATA code
  static String getIata(String input) {
    final query = input.trim().toLowerCase();

    // If user already typed an IATA code like HYD
    for (final airport in airports) {
      if (airport.iata.toLowerCase() == query) {
        return airport.iata;
      }
    }

    // Match by city name
    for (final airport in airports) {
      if (airport.city.toLowerCase() == query) {
        return airport.iata;
      }
    }

    // Match partial city name
    for (final airport in airports) {
      if (airport.city.toLowerCase().contains(query)) {
        return airport.iata;
      }
    }

    // Fallback: return uppercase input
    return input.toUpperCase();
  }

  /// Backwards-compatible async loader.
  /// Some parts of the app call `AirportService.loadAirports()` during
  /// startup. Previously this loaded a larger dataset; for now we keep a
  /// no-op async method so the call site doesn't fail.
  static Future<void> loadAirports() async {
    // Intentionally left empty. If in future we fetch a remote airport
    // database, populate `airports` here.
    await Future<void>.value();
  }
}