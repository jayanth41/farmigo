import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple booking helper that encapsulates Supabase insert logic.
class BookingService {
  /// Creates a booking row in the `bookings` table.
  /// Returns true when the insert succeeded, false otherwise.
  static Future<bool> createBooking({
    required String propertyId,
    required String visitDate,
    String status = 'pending',
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[BookingService] no authenticated user');
        return false;
      }

      final response = await supabase.from('bookings').insert({
        'property_id': propertyId,
        'user_id': user.id,
        'visit_date': visitDate,
        'status': status,
      });

      // Supabase client returns the inserted row(s) on success. We'll
      // treat any non-null response as success.
      debugPrint('[BookingService] insert response: $response');
      return response != null;
    } catch (e, st) {
      debugPrint('[BookingService] exception creating booking: $e');
      debugPrint('$st');
      return false;
    }
  }
}
