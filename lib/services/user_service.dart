import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// UserService migrated to Firestore. This provides a minimal compatibility
/// layer for existing callers that previously used an external user store.
class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists({
    required String name,
    required String phone,
    String role = 'user',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'name': name,
          'phone': phone,
          'role': role,
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('createUserIfNotExists error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({'name': name, 'phone': phone}, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }
}
