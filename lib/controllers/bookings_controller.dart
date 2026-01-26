import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;   // 🔥 THIS WAS MISSING
  var bookings = [].obs;

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        bookings.clear();
        return;
      }

      final res = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('user_id', user.id);

      bookings.value = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      bookings.clear();
      print("Error fetching bookings: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
