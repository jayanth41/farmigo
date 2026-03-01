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
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;

        // 🔥 Auto-complete logic
        if (data['status'] == 'upcoming' && data['checkOut'] != null) {
          final checkout = DateTime.tryParse(data['checkOut']);
          if (checkout != null && DateTime.now().isAfter(checkout)) {
            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(doc.id)
                .update({'status': 'completed'});

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('bookings')
                .doc(doc.id)
                .update({'status': 'completed'});

            data['status'] = 'completed';
          }
        }

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final firestore = FirebaseFirestore.instance;
      final bookingRef = firestore.collection('bookings').doc();

      final bookingData = {
        'listingId': listingId,
        'propertyName': propertyName,
        'location': location,
        'imageUrl': imageUrl,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'totalPrice': totalPrice,
        'ownerId': ownerId,
        'userId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      // Global bookings collection
      batch.set(bookingRef, bookingData);

      // User subcollection copy
      final userBookingRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .doc(bookingRef.id);

      batch.set(userBookingRef, bookingData);

      await batch.commit();

      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('addBooking failed: $e');
      return false;
    }
  }

  Future<bool> approveBooking(String bookingId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final bookingRef = firestore.collection('bookings').doc(bookingId);
      final bookingSnap = await bookingRef.get();
      if (!bookingSnap.exists) return false;

      final data = bookingSnap.data() as Map<String, dynamic>;
      final userId = data['userId'];

      final batch = firestore.batch();

      batch.update(bookingRef, {
        'status': 'upcoming',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (userId != null) {
        final userBookingRef = firestore
            .collection('users')
            .doc(userId)
            .collection('bookings')
            .doc(bookingId);

        batch.update(userBookingRef, {
          'status': 'upcoming',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('approveBooking failed: $e');
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

  Future<List<Map<String, dynamic>>> fetchOwnerBookings(String ownerId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('fetchOwnerBookings failed: $e');
      return [];
    }
  }
}