import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_helper.dart';
import 'network_utils.dart';

class ReviewService {
  final FirebaseFirestore? _db = FirebaseHelper.isLikelyAvailable() ? FirebaseFirestore.instance : null;

  Future<void> addReview({
    required String reviewText,
    required int rating,
    required String propertyId,
    required String userId,
  }) async {
    final doc = {
      'reviewText': reviewText,
      'rating': rating,
      'propertyId': propertyId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_db == null) {
      debugPrint('⚠️ ReviewService.addReview: Firestore unavailable, skipping');
      return;
    }

    // optional network check for better diagnostics
    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ ReviewService.addReview: No network, skipping');
      return;
    }

    try {
      final db = _db!;
      await db.collection('reviews').add(doc);
    } catch (e) {
      debugPrint('❌ ReviewService.addReview error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReviews(String propertyId) {
    if (_db == null) {
      debugPrint('⚠️ ReviewService.getReviews: Firestore unavailable, returning empty stream');
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    try {
      final db = _db!;
      return db
          .collection('reviews')
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((e) => debugPrint('❌ ReviewService.getReviews stream error: $e'));
    } catch (e) {
      debugPrint('❌ ReviewService.getReviews error: $e');
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
  }
}
