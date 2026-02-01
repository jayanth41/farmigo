  import 'package:flutter/foundation.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';


  class BookingService {
    /// Create a booking row in Supabase. Fields are optional where appropriate.
    ///
    /// - propertyId: either a UUID property_id or a string that will be stored in
    ///   property_name.
    /// - checkIn/checkOut: DateTimes (will be stored as ISO strings)
    /// - imageUrl, totalPrice, location: optional metadata
    static Future<bool> createBooking({
      required String propertyId,
      DateTime? visitDate,
      DateTime? checkIn,
      DateTime? checkOut,
      String? propertyName,
      String? location,
      String? imageUrl,
      num? totalPrice,
      String status = 'upcoming',
    }) async {
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        final userId = user?.id; // nullable

        // base insert map
        final insertMap = <String, dynamic>{
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

        if (imageUrl != null) {
          insertMap['image_url'] = imageUrl;
        }

        if (checkIn != null) {
          insertMap['check_in'] = checkIn.toIso8601String();
        } else if (visitDate != null) {
          insertMap['check_in'] = visitDate.toIso8601String();
        }

        if (checkOut != null) {
          insertMap['check_out'] = checkOut.toIso8601String();
        }

        if (totalPrice != null) {
          insertMap['total_price'] = totalPrice;
        }

        debugPrint('Booking insert map: $insertMap');

        final inserted = await supabase.from('bookings').insert(insertMap).select();

        debugPrint('Booking insert result: $inserted');

        return true;
      } catch (e) {
        debugPrint('Booking error: $e');
        return false;
      }
    }
  }

