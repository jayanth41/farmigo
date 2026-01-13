import 'package:get/get.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;
  var bookings = [].obs;

  @override
  void onInit() {
    fetchBookings();
    super.onInit();
  }

  void fetchBookings() async {
    isLoading.value = true;

    // temporary dummy data
    await Future.delayed(const Duration(seconds: 1));

    bookings.value = [
      {
        'name': 'Night Garden Stay',
        'date': '10 Feb 2026',
        'price': 10000,
      }
    ];

    isLoading.value = false;
  }
}
