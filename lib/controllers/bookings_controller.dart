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
        'bookingId': 'BKG-1001',
        'name': 'The Night Garden Stay',
        'location': 'Anajpur, Hyderabad',
        'image': 'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=1200&auto=format&fit=crop&q=80',
        'checkIn': '2026-02-10',
        'checkOut': '2026-02-12',
        'guests': '4',
        'totalAmount': 20000,
        'status': 'upcoming',
      },
      {
        'bookingId': 'BKG-1002',
        'name': 'Organic Farm Retreat',
        'location': 'Tandur, Telangana',
        'image': 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=1200&auto=format&fit=crop&q=80',
        'checkIn': '2025-12-01',
        'checkOut': '2025-12-03',
        'guests': '2',
        'totalAmount': 3600,
        'status': 'completed',
      },
      {
        'bookingId': 'BKG-1003',
        'name': 'Heritage Farm Stay',
        'location': 'Vikarabad, Telangana',
        'image': '', // empty image will fall back to placeholder
        'checkIn': '2026-03-05',
        'checkOut': '2026-03-06',
        'guests': '6',
        'totalAmount': 4400,
        'status': 'confirmed',
      },
    ];

    isLoading.value = false;
  }
}
