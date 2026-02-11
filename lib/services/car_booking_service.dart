import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/car_booking.dart';

class CarBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculate pricing breakdown for a car booking
  static Map<String, int> calculatePricing({
    required DateTime startDate,
    required DateTime endDate,
    required int pricePerDay,
    int? weekendPrice,
    int? hourlyPrice,
    int? driverHourlyCharge,
    bool driverRequested = false,
    int? hours,
  }) {
    int weekdayTotal = 0;
    int weekendTotal = 0;
    int driverTotal = 0;
    int hourlyTotal = 0;

    // If same-day booking with hours, calculate hourly
    if (isSameDayBooking(startDate, endDate) && hours != null && hourlyPrice != null) {
      hourlyTotal = hours * hourlyPrice;
      if (driverRequested && driverHourlyCharge != null) {
        driverTotal = hours * driverHourlyCharge;
      }
      return {
        'weekdayTotal': 0,
        'weekendTotal': 0,
        'hourlyTotal': hourlyTotal,
        'driverTotal': driverTotal,
        'finalTotal': hourlyTotal + driverTotal,
      };
    }

    // Multi-day booking
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final isWeekend = current.weekday == DateTime.saturday || current.weekday == DateTime.sunday;

      if (isWeekend && weekendPrice != null) {
        weekendTotal += weekendPrice;
      } else {
        weekdayTotal += pricePerDay;
      }

      current = current.add(const Duration(days: 1));
    }

    // Calculate driver charges for multi-day (per day)
    if (driverRequested && driverHourlyCharge != null) {
      final numberOfDays = endDate.difference(startDate).inDays;
      driverTotal = numberOfDays * driverHourlyCharge;
    }

    final finalTotal = weekdayTotal + weekendTotal + driverTotal;

    return {
      'weekdayTotal': weekdayTotal,
      'weekendTotal': weekendTotal,
      'hourlyTotal': hourlyTotal,
      'driverTotal': driverTotal,
      'finalTotal': finalTotal,
    };
  }

  /// Check if booking is same-day
  static bool isSameDayBooking(DateTime startDate, DateTime endDate) {
    return startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
  }

  /// Create a car booking in Firestore
  static Future<CarBooking?> createCarBooking({
    required String carId,
    required String carName,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required int pricePerDay,
    int? weekendPrice,
    int? hourlyPrice,
    int? driverHourlyCharge,
    bool driverRequested = false,
    int? hours,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Calculate pricing
      final pricing = calculatePricing(
        startDate: startDate,
        endDate: endDate,
        pricePerDay: pricePerDay,
        weekendPrice: weekendPrice,
        hourlyPrice: hourlyPrice,
        driverHourlyCharge: driverHourlyCharge,
        driverRequested: driverRequested,
        hours: hours,
      );

      // Get guest FCM token
      String? guestFcmToken;
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        guestFcmToken = userDoc.data()?['fcmToken'] as String?;
      } catch (e) {
        debugPrint('Failed to fetch FCM token: $e');
      }

      // Create booking object
      final booking = CarBooking(
        carId: carId,
        carName: carName,
        userId: user.uid,
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        hours: hours,
        pricePerDay: pricePerDay,
        weekendPrice: weekendPrice,
        hourlyPrice: hourlyPrice,
        driverHourlyCharge: driverHourlyCharge,
        driverRequested: driverRequested,
        weekdayTotal: pricing['weekdayTotal'] ?? 0,
        weekendTotal: pricing['weekendTotal'] ?? 0,
        driverTotal: pricing['driverTotal'] ?? 0,
        hourlyTotal: pricing['hourlyTotal'] ?? 0,
        finalTotal: pricing['finalTotal'] ?? 0,
        status: 'confirmed',
        createdAt: DateTime.now(),
        guestFcmToken: guestFcmToken,
      );

      // Save to Firestore
      final docRef = _firestore.collection('car_bookings').doc();
      final bookingId = docRef.id;

      // Save main booking document
      await docRef.set(booking.toFirestore());

      // Mirror in user's bookings subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('car_bookings')
          .doc(bookingId)
          .set(booking.toFirestore());

      // Send notification to owner
      await _sendOwnerNotification(
        ownerId: ownerId,
        carId: carId,
        startDate: startDate,
        endDate: endDate,
        bookingId: bookingId,
      );

      // Update booking with ID
      final finalBooking = CarBooking(
        id: bookingId,
        carId: booking.carId,
        carName: booking.carName,
        userId: booking.userId,
        ownerId: booking.ownerId,
        startDate: booking.startDate,
        endDate: booking.endDate,
        hours: booking.hours,
        pricePerDay: booking.pricePerDay,
        weekendPrice: booking.weekendPrice,
        hourlyPrice: booking.hourlyPrice,
        driverHourlyCharge: booking.driverHourlyCharge,
        driverRequested: booking.driverRequested,
        weekdayTotal: booking.weekdayTotal,
        weekendTotal: booking.weekendTotal,
        driverTotal: booking.driverTotal,
        hourlyTotal: booking.hourlyTotal,
        finalTotal: booking.finalTotal,
        status: booking.status,
        createdAt: booking.createdAt,
        guestFcmToken: booking.guestFcmToken,
      );

      debugPrint('Car booking created: $bookingId');
      return finalBooking;
    } catch (e) {
      debugPrint('Failed to create car booking: $e');
      return null;
    }
  }

  /// Send notification to car owner
  static Future<void> _sendOwnerNotification({
    required String ownerId,
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String bookingId,
  }) async {
    try {
      final notification = {
        'ownerId': ownerId,
        'propertyId': carId,
        'message': 'New car booking from ${_formatDate(startDate)} to ${_formatDate(endDate)}',
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'car_booking',
      };

      await _firestore.collection('owner_notifications').doc().set(notification);

      // Try to send FCM notification via Cloud Function
      // This would be implemented as a Cloud Function call
      debugPrint('Owner notification queued for $ownerId');
    } catch (e) {
      debugPrint('Failed to send owner notification: $e');
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Fetch owner's car bookings
  /// Note: Ordering is done in-memory until Firestore composite index is available
  static Stream<List<CarBooking>> getOwnerCarBookings(String ownerId) {
    return _firestore
        .collection('car_bookings')
        .where('ownerId', isEqualTo: ownerId)
        // Removed .orderBy('createdAt') to avoid composite index requirement
        // Sorting will be done in-memory below
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => CarBooking.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
          
          // Sort by createdAt in descending order (most recent first)
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  /// Fetch owner's unread notifications
  static Stream<int> getUnreadNotificationCount(String ownerId) {
    return _firestore
        .collection('owner_notifications')
        .where('ownerId', isEqualTo: ownerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('owner_notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Get car details from Firestore
  static Future<Map<String, dynamic>?> getCarDetails(String carId) async {
    try {
      final doc = await _firestore.collection('properties').doc(carId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Failed to fetch car details: $e');
      return null;
    }
  }

  /// Get blocked dates for a car
  static Future<List<DateTime>> getBlockedDates(String carId) async {
    try {
      final doc = await _firestore.collection('properties').doc(carId).get();
      final data = doc.data();
      if (data == null) return [];

      final blockedDates = data['blockedDates'] as List<dynamic>?;
      if (blockedDates == null) return [];

      return blockedDates
          .map((ts) => (ts as Timestamp).toDate())
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch blocked dates: $e');
      return [];
    }
  }
}
