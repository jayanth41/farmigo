import '../models/airport.dart';

class AirportService {
  /// Major airports shown first in autocomplete
  static final List<String> popularAirports = [
    "HYD", // Hyderabad
    "DEL", // Delhi
    "BOM", // Mumbai
    "BLR", // Bangalore
    "MAA", // Chennai
    "CCU", // Kolkata
  ];

  static final List<Airport> airports = [
    Airport(name: "Rajiv Gandhi International Airport", city: "Hyderabad", iata: "HYD"),
    Airport(name: "Indira Gandhi International Airport", city: "Delhi", iata: "DEL"),
    Airport(name: "Chhatrapati Shivaji Maharaj International Airport", city: "Mumbai", iata: "BOM"),
    Airport(name: "Kempegowda International Airport", city: "Bangalore", iata: "BLR"),
    Airport(name: "Chennai International Airport", city: "Chennai", iata: "MAA"),
    Airport(name: "Netaji Subhas Chandra Bose Airport", city: "Kolkata", iata: "CCU"),
    Airport(name: "Sardar Vallabhbhai Patel Airport", city: "Ahmedabad", iata: "AMD"),
    Airport(name: "Cochin International Airport", city: "Kochi", iata: "COK"),
    Airport(name: "Pune International Airport", city: "Pune", iata: "PNQ"),
    Airport(name: "Goa International Airport", city: "Goa", iata: "GOI"),
    Airport(name: "Jaipur International Airport", city: "Jaipur", iata: "JAI"),
    Airport(name: "Lucknow Airport", city: "Lucknow", iata: "LKO"),
    Airport(name: "Chandigarh Airport", city: "Chandigarh", iata: "IXC"),
  ];

  static List<Airport> search(String query) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) return [];

    final results = airports.where((airport) {
      return airport.city.toLowerCase().contains(q) ||
          airport.name.toLowerCase().contains(q) ||
          airport.iata.toLowerCase().contains(q);
    }).toList();

    // Smart ranking (exact match → startsWith → popular airports)
    results.sort((a, b) {
      int score(Airport airport) {
        if (airport.iata.toLowerCase() == q) return 0;
        if (airport.city.toLowerCase().startsWith(q)) return 1;
        if (airport.name.toLowerCase().startsWith(q)) return 2;
        if (popularAirports.contains(airport.iata)) return 3;
        return 4;
      }

      return score(a).compareTo(score(b));
    });

    // Limit results for smooth autocomplete UI
    return results.take(8).toList();
  }

  // Convert user input (city or IATA) to a valid IATA code
  static String getIata(String input) {
    final text = input.trim();

    // Extract IATA if user selected "City (IATA)"
    final match = RegExp(r"\((.*?)\)").firstMatch(text);
    if (match != null) {
      return match.group(1)!.toUpperCase();
    }

    final query = text.toLowerCase();

    // Direct IATA match
    for (final airport in airports) {
      if (airport.iata.toLowerCase() == query) {
        return airport.iata;
      }
    }

    // Exact city match
    for (final airport in airports) {
      if (airport.city.toLowerCase() == query) {
        return airport.iata;
      }
    }

    // Partial city match
    for (final airport in airports) {
      if (airport.city.toLowerCase().contains(query)) {
        return airport.iata;
      }
    }

    // Fallback
    return text.toUpperCase();
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