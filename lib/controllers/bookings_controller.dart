import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;   // 🔥 THIS WAS MISSING
  var bookings = [].obs;

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;
      final user = Supabase.instance.client.auth.currentUser;
      final supabase = Supabase.instance.client;

      dynamic res;
      if (user != null) {
        res = await supabase.from('bookings').select().eq('user_id', user.id);
      } else {
        // Show guest bookings for non-authenticated users (bookings created with user_id = 'guest')
        res = await supabase.from('bookings').select().eq('user_id', 'guest');
      }

      bookings.value = List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      bookings.clear();
      debugPrint("Error fetching bookings: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
