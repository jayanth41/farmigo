import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Read bookings from Firestore
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> results = [];
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        results.add(data);
      }

      bookings.value = results;
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final bookingId = id?.toString();
      if (bookingId == null || bookingId.isEmpty) return false;

      final batch = FirebaseFirestore.instance.batch();
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {'status': 'cancelled'});

      final userBookingRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookings').doc(bookingId);
      batch.update(userBookingRef, {'status': 'cancelled'});

      await batch.commit();

      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('cancelBooking failed: $e');
      return false;
    }
  }
}