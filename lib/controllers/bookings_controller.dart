import 'package:get/get.dart';

class BookingsController extends GetxController {
  var bookings = [].obs;

  void addBooking(dynamic booking) {
    bookings.add(booking);
  }
}
