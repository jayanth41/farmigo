import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;
  var bookings = [].obs;

  Future<void> fetchBookings() async {
  try {
    isLoading.value = true;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint("No user logged in, skipping fetchBookings");
      return;
    }

    debugPrint("fetchBookings: userId=${user.id}");

    final res = await supabase
        .from('bookings')
        .select()
        .eq('user_id', user.id);

    debugPrint("fetchBookings: raw response = $res");

    bookings.value = List<Map<String, dynamic>>.from(res);
  } catch (e) {
    bookings.clear();
    debugPrint("Error fetching bookings: $e");
  } finally {
    isLoading.value = false;
  }
}

}

