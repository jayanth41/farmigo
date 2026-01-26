import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple booking helper that encapsulates Supabase insert logic.
class BookingService {
  /// Creates a booking row in the `bookings` table.
  /// Returns true when the insert succeeded, false otherwise.
 static Future<bool> createBooking({
  required String propertyId,
  required DateTime visitDate,
  String status = 'pending',
}) async {
  try {
    final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser;

// TEMP: allow booking without login
final userId = user?.id ?? 'test-user-id';


   await supabase.from('bookings').insert({
  'property_id': propertyId,
  'user_id': userId,
  'visit_date': visitDate.toIso8601String(),
  'status': status,
});


    return true;
  } catch (e) {
    debugPrint('Booking error: $e');
    return false;
  }
}
}
