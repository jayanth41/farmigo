import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  static Future<bool> createBooking({
    required String propertyId,
    required DateTime visitDate,
    String? propertyName,
    String? location,
    String status = 'upcoming',
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id; // nullable

      // base insert map
      final insertMap = <String, dynamic>{
        'visit_date': visitDate.toIso8601String(),
        'status': status,
      };

      // add user_id only if logged in
      if (userId != null) {
        insertMap['user_id'] = userId;
      }

      // property id or name
      final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

      if (uuidRegex.hasMatch(propertyId)) {
        insertMap['property_id'] = propertyId;
      } else {
        insertMap['property_name'] = propertyName ?? propertyId;
      }

      if (location != null) {
        insertMap['location'] = location;
      }

      debugPrint('Booking insert map: $insertMap');

      final inserted =
          await supabase.from('bookings').insert(insertMap).select();

      debugPrint('Booking insert result: $inserted');

      return true;
    } catch (e) {
      debugPrint('Booking error: $e');
      return false;
    }
  }
}
