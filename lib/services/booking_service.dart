import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:get/get.dart';

import 'reward_service.dart';

class BookingService {
  /// Create a booking in Firestore and mirror a minimal booking entry under
  /// users/{uid}/bookings/{bookingId}. Returns true on success, false on failure.
  static Future<bool> createBooking({
    required String propertyId,
    String? ownerId,
    String? propertyName,
    String? location,
    String? imageUrl,
    String? checkIn,
    String? checkOut,
    num? totalPrice,
    int guests = 1,
    String status = 'confirmed',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final uid = user.uid;

      // Parse checkIn/checkOut strings (ISO) if provided
      DateTime? checkInDt = checkIn != null && checkIn.isNotEmpty ? DateTime.tryParse(checkIn) : null;
      DateTime? checkOutDt = checkOut != null && checkOut.isNotEmpty ? DateTime.tryParse(checkOut) : null;

      final bookingsColl = FirebaseFirestore.instance.collection('bookings');
      final bookingDoc = bookingsColl.doc();
      final bookingId = bookingDoc.id;

      // Prepare booking document data
      final Map<String, dynamic> bookingData = {
        'userId': uid,
        'listingId': propertyId,
        'ownerId': ownerId ?? '',
        'checkIn': checkInDt != null ? Timestamp.fromDate(checkInDt) : FieldValue.serverTimestamp(),
        'checkOut': checkOutDt != null ? Timestamp.fromDate(checkOutDt) : FieldValue.serverTimestamp(),
        'guests': guests,
        'totalAmount': totalPrice ?? 0,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'propertyName': propertyName ?? '',
        'location': location ?? '',
        'imageUrl': imageUrl ?? '',
      };

      // Prepare minimal user booking entry
      final userBookingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .doc(bookingId);

      final Map<String, dynamic> userBookingData = {
        'listingId': propertyId,
        'checkIn': bookingData['checkIn'],
        'checkOut': bookingData['checkOut'],
        'status': status,
        'totalAmount': bookingData['totalAmount'],
      };

      // Write both documents in a batch for atomicity
      final batch = FirebaseFirestore.instance.batch();
      batch.set(bookingDoc, bookingData);
      batch.set(userBookingRef, userBookingData);

      await batch.commit();

      debugPrint('Booking created: $bookingId for UID: $uid');

      // After successful booking creation, award reward points.
      // RewardService will attempt to update users/{uid}.rewardPoints.
      final rewardOk = await RewardService.addRewardPointsForBooking(points: 50);
      if (!rewardOk) {
        debugPrint('Failed to apply reward points for booking $bookingId');
      }

      return true;
    } on FirebaseException catch (e) {
      // Handle Firestore-specific errors (e.g., permission denied)
      debugPrint('createBooking FirebaseException: ${e.code} ${e.message}');
      if (e.code.toString().toLowerCase().contains('permission')) {
        try {
          Get.snackbar('Booking failed', 'Booking failed: Check Firestore rules');
        } catch (_) {
          // ignore if Get isn't available at runtime
        }
      }
      return false;
    } catch (e) {
      debugPrint('createBooking error: $e');
      return false;
    }
  }
}

