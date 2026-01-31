import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_utils.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

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
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ ReviewService.addReview: No network, skipping');
      return;
    }

    try {
      await _supabase.from('reviews').insert(doc);
    } catch (e) {
      debugPrint('❌ ReviewService.addReview error: $e');
    }
  }

  /// Fetch reviews for a property as a single-shot list. If you need realtime
  /// updates, consider wiring Supabase Realtime separately.
  Future<List<Map<String, dynamic>>> getReviews(String propertyId) async {
    try {
  final res = await _supabase.from('reviews').select().eq('propertyId', propertyId).order('createdAt', ascending: false);
  return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('❌ ReviewService.getReviews error: $e');
      return [];
    }
  }
}
