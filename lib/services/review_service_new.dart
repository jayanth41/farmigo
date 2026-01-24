import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    await _db.collection('reviews').add(doc);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReviews(String propertyId) {
    return _db
        .collection('reviews')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
