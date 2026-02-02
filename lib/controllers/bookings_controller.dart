import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/booking_service.dart';

class BookingsController extends GetxController {
  var isLoading = true.obs;
  var bookings = <Map<String, dynamic>>[].obs;

  /// Fetch bookings for the currently logged-in user.
  /// No bookings backend is configured in this migration; this returns an
  /// empty list to avoid crashes. Replace with Firestore/REST backend
  /// integration when available.
  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        bookings.clear();
        return;
      }

      // No backend configured for bookings yet. Keep empty list to avoid crashes.
      bookings.clear();
    } catch (e) {
      bookings.clear();
      debugPrint('Error fetching bookings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addBooking({
    required String listingId,
    required String propertyName,
    required String location,
    required String imageUrl,
    required String checkIn,
    required String checkOut,
    required num totalPrice,
    String? ownerId,
  }) async {
    try {
      final success = await BookingService.createBooking(
        propertyId: listingId,
        ownerId: ownerId,
        propertyName: propertyName,
        location: location,
        imageUrl: imageUrl,
        checkIn: checkIn,
        checkOut: checkOut,
        totalPrice: totalPrice,
      );
      return success;
    } catch (e) {
      debugPrint('addBooking failed: $e');
      return false;
    }
  }

  Future<bool> cancelBooking(dynamic id) async {
    debugPrint('cancelBooking called but no backend configured');
    return false;
  }
}