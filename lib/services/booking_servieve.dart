class BookingService {
  static Future<bool> createBooking({
    required String farmhouseId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
