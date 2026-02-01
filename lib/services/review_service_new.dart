import 'package:flutter/foundation.dart';

import 'network_utils.dart';

/// ReviewService: backend implementation not present in this migration.
/// These methods are currently no-ops and return empty results so the app
/// remains runnable. Replace with Firestore or other backend when ready.
class ReviewService {
  Future<void> addReview({
    required String reviewText,
    required int rating,
    required String propertyId,
    required String userId,
  }) async {
    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ ReviewService.addReview: No network, skipping');
      return;
    }
    debugPrint('ReviewService.addReview called but backend not implemented');
    return;
  }

  Future<List<Map<String, dynamic>>> getReviews(String propertyId) async {
    debugPrint('ReviewService.getReviews called but backend not implemented');
    return [];
  }
}
