import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/faq_model.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all FAQs for a property
  Future<List<FAQModel>> getFAQsByPropertyId(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('faqs')
          .orderBy('order')
          .get();
      
      return querySnapshot.docs
          .map((doc) => FAQModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      return [];
    }
  }

  /// Add a new FAQ
  Future<bool> addFAQ({
    required String propertyId,
    required String question,
    required String answer,
  }) async {
    try {
      final faqsRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('faqs');
      
      final count = await faqsRef.count().get();
      
      await faqsRef.add({
        'propertyId': propertyId,
        'question': question,
        'answer': answer,
        'order': count.count,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding FAQ: $e');
      return false;
    }
  }

  /// Update FAQ
  Future<bool> updateFAQ({
    required String propertyId,
    required String faqId,
    required String question,
    required String answer,
  }) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('faqs')
          .doc(faqId)
          .update({
        'question': question,
        'answer': answer,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating FAQ: $e');
      return false;
    }
  }

  /// Delete FAQ
  Future<bool> deleteFAQ(String propertyId, String faqId) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('faqs')
          .doc(faqId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting FAQ: $e');
      return false;
    }
  }
}
