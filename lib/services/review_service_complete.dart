import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

class ReviewServiceComplete {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all reviews for a property
  Future<List<ReviewModel>> getReviewsByPropertyId(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  /// Add a new review
  Future<bool> addReview({
    required String propertyId,
    required String userId,
    required String userName,
    required String userImage,
    required int rating,
    required String reviewText,
    List<String> imageUrls = const [],
  }) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .add({
        'propertyId': propertyId,
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'rating': rating,
        'reviewText': reviewText,
        'imageUrls': imageUrls,
        'createdAt': DateTime.now().toIso8601String(),
        'helpfulCount': 0,
      });
      
      // Update property average rating
      await _updatePropertyRating(propertyId);
      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  /// Update property average rating
  Future<void> _updatePropertyRating(String propertyId) async {
    try {
      final reviews = await getReviewsByPropertyId(propertyId);
      if (reviews.isEmpty) return;
      
      final averageRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      
      await _firestore.collection('properties').doc(propertyId).update({
        'averageRating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      debugPrint('Error updating property rating: $e');
    }
  }

  /// Delete review
  Future<bool> deleteReview(String propertyId, String reviewId) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .doc(reviewId)
          .delete();
      
      await _updatePropertyRating(propertyId);
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markAsHelpful(String propertyId, String reviewId) async {
    try {
      final reviewRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .doc(reviewId);
      
      await reviewRef.update({
        'helpfulCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      debugPrint('Error marking review as helpful: $e');
      return false;
    }
  }
}
