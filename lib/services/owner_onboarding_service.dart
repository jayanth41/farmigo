import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/owner_onboarding_model.dart';

/// Service to manage owner onboarding state and persistence
class OwnerOnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Get or create onboarding data for current user
  Future<OwnerOnboardingModel> getOrCreateOnboardingData() async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      final docRef = _firestore.collection('owners').doc(userId);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        debugPrint('[OnboardingService] Loaded existing onboarding data');
        return OwnerOnboardingModel.fromFirestore(
          snapshot as DocumentSnapshot<Map<String, dynamic>>,
        );
      } else {
        debugPrint('[OnboardingService] Creating new onboarding data');
        final newModel = OwnerOnboardingModel.empty(userId);
        await docRef.set(newModel.toFirestore());
        return newModel;
      }
    } catch (e) {
      debugPrint('[OnboardingService] Error: $e');
      rethrow;
    }
  }

  /// Mark a screen as completed
  Future<void> markScreenCompleted(String screenName) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('owners').doc(userId).update({
        'completed_screens': FieldValue.arrayUnion([screenName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Marked screen completed: $screenName');
    } catch (e) {
      debugPrint('[OnboardingService] Error marking screen: $e');
      rethrow;
    }
  }

  /// Update onboarding status
  Future<void> updateOnboardingStatus(String status) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('owners').doc(userId).update({
        'onboarding_status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Updated status to: $status');
    } catch (e) {
      debugPrint('[OnboardingService] Error updating status: $e');
      rethrow;
    }
  }

  /// Mark property details as completed
  Future<void> markPropertyDetailsCompleted() async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('owners').doc(userId).update({
        'property_details_completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Marked property details completed');
    } catch (e) {
      debugPrint('[OnboardingService] Error: $e');
      rethrow;
    }
  }

  /// Mark properties as added
  Future<void> markPropertiesAdded() async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('owners').doc(userId).update({
        'properties_added': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Marked properties added');
    } catch (e) {
      debugPrint('[OnboardingService] Error: $e');
      rethrow;
    }
  }

  /// Set active role for multi-owner users
  Future<void> setActiveRole(String role) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      if (!['farmhouse', 'cOwner'].contains(role)) {
        throw Exception('Invalid role: $role');
      }

      await _firestore.collection('owners').doc(userId).update({
        'activeRole': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Set active role to: $role');
    } catch (e) {
      debugPrint('[OnboardingService] Error setting role: $e');
      rethrow;
    }
  }

  /// Update verification status
  Future<void> updateVerificationStatus(String status) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      if (!['pending_verification', 'verified', 'rejected'].contains(status)) {
        throw Exception('Invalid verification status: $status');
      }

      await _firestore.collection('owners').doc(userId).update({
        'verification_status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Updated verification status to: $status');
    } catch (e) {
      debugPrint('[OnboardingService] Error: $e');
      rethrow;
    }
  }

  /// Mark email verification as sent
  Future<void> markEmailVerificationSent() async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('owners').doc(userId).update({
        'email_verification_sent': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OnboardingService] Marked email verification sent');
    } catch (e) {
      debugPrint('[OnboardingService] Error: $e');
      rethrow;
    }
  }

  /// Get onboarding data stream (for real-time updates)
  Stream<OwnerOnboardingModel?> getOnboardingStream() {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('owners')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return OwnerOnboardingModel.fromFirestore(
          snapshot as DocumentSnapshot<Map<String, dynamic>>,
        );
      }
      return null;
    });
  }

  /// Check if onboarding can proceed to next screen
  bool canProceedToScreen2(OwnerOnboardingModel model) {
    return model.isScreenCompleted('screen_1');
  }

  bool canProceedToScreen3(OwnerOnboardingModel model) {
    return model.propertyDetailsCompleted && model.isScreenCompleted('screen_2');
  }

  bool canProceedToDashboard(OwnerOnboardingModel model) {
    return model.onboardingStatus == 'completed';
  }
}
