import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;
  var bookings = <Map<String, dynamic>>[].obs;

  /// Fetch bookings for the currently logged-in user and map
  /// DB snake_case fields to UI-friendly camelCase keys.
  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("No user logged in, skipping fetchBookings");
        bookings.clear();
        return;
      }

      debugPrint("fetchBookings: userId=${user.id}");

  final res = await supabase.from('bookings').select().eq('user_id', user.id);

      debugPrint("fetchBookings: raw response = $res");

      // Filter client-side for this user's bookings (some Supabase setups
      // may already filter server-side; the query above can be adjusted).
  final List raw = List<Map<String, dynamic>>.from(res);

      final mapped = raw
          .where((r) => (r['user_id'] ?? r['userId'] ?? '') == user.id)
          .map<Map<String, dynamic>>((r) => {
                'id': r['id'],
                'propertyName': r['property_name'] ?? r['propertyName'] ?? r['property'] ?? '',
                'imageUrl': r['image_url'] ?? r['imageUrl'] ?? r['image'] ?? r['propertyImage'] ?? '',
                'checkIn': r['check_in'] ?? r['checkIn'] ?? r['checkInDate'] ?? '',
                'checkOut': r['check_out'] ?? r['checkOut'] ?? r['checkOutDate'] ?? '',
                'totalPrice': r['total_price'] ?? r['totalPrice'] ?? r['price'] ?? 0,
                'location': r['location'] ?? r['place'] ?? '',
                'status': r['status'] ?? 'upcoming',
                'raw': r,
              })
          .toList();

      bookings.value = mapped;
    } catch (e) {
      bookings.clear();
      debugPrint("Error fetching bookings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Insert a new booking for the current user. Expects dates in ISO string
  /// format (or any string accepted by your backend). On success it refreshes
  /// the local bookings list.
  Future<bool> addBooking({
    required String propertyName,
    required String location,
    required String imageUrl,
    required String checkIn,
    required String checkOut,
    required num totalPrice,
  }) async {
    try {
      isLoading.value = true;
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No logged in user');

      final insertRes = await supabase.from('bookings').insert({
        'user_id': user.id,
        'property_name': propertyName,
        'location': location,
        'image_url': imageUrl,
        'check_in': checkIn,
        'check_out': checkOut,
        'total_price': totalPrice,
        'status': 'upcoming',
      }).select();

      debugPrint('addBooking: insertRes=$insertRes');

      // Refresh bookings after successful insert
      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('Error adding booking: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel a booking by id (sets status = 'cancelled') and refreshes the list.
  Future<bool> cancelBooking(dynamic id) async {
    try {
      isLoading.value = true;
      final supabase = Supabase.instance.client;

      await supabase.from('bookings').update({'status': 'cancelled'}).eq('id', id).select();

      // Refresh bookings after update
      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}