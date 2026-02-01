import 'package:flutter/foundation.dart';

class OwnerService {
  /// Owner-related backend functionality is not implemented in this
  /// migration. These are safe no-op implementations to keep the UI
  /// functional. Implement Firestore equivalents when you need owner
  /// booking persistence.

  Future<List<Map<String, dynamic>>> fetchOwnerBookings() async {
    debugPrint('fetchOwnerBookings called but backend not implemented');
    return [];
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    debugPrint('updateBookingStatus called for $bookingId -> $status (not persisted)');
    return;
  }
}
