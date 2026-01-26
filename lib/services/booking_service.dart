import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple booking helper that encapsulates Supabase insert logic.
class BookingService {
  /// Creates a booking row in the `bookings` table.
  /// Returns true when the insert succeeded, false otherwise.
  static Future<bool> createBooking({
    required String propertyId,
    required DateTime visitDate,
    String? propertyName,
    String? location,
    DateTime? checkOutDate,
    int? guests,
    double? totalPrice,
    String status = 'upcoming',
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // Allow guest bookings: if user not logged in, use a 'guest' placeholder id.
      final userId = user?.id ?? 'guest';

      final insertMap = <String, dynamic>{
        'user_id': userId,
        'visit_date': visitDate.toIso8601String(),
        'status': status,
      };

      // If propertyId looks like a UUID, store it as property_id; otherwise
      // store the human-readable property_name instead to avoid DB type errors.
      final uuidRegex = RegExp(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");
      if (uuidRegex.hasMatch(propertyId)) {
        insertMap['property_id'] = propertyId;
      } else {
        insertMap['property_name'] = propertyName ?? propertyId;
      }

  if (location != null) insertMap['location'] = location;
  // Only insert the minimal set of columns we know exist in the bookings
  // table to avoid PostgREST errors for unknown columns.

      debugPrint('Booking insert map: $insertMap');
      final inserted = await supabase.from('bookings').insert(insertMap).select();
      debugPrint('Booking insert result: $inserted');

      // If insert returned rows, assume success
      if (inserted is List && inserted.isEmpty) {
        debugPrint('Booking insert returned no rows: $inserted');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Booking error: $e');
      return false;
    }
  }
}
