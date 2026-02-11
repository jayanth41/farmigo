import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch user roles from Firestore
  /// Returns list of roles: ["farmhouse_owner", "car_owner", etc]
  static Future<List<String>> getUserRoles(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final roles = (doc.data()?['roles'] as List<dynamic>?)
          ?.cast<String>()
          .toList() ??
          [];
      debugPrint('[AuthService] User roles: $roles');
      return roles;
    } catch (e) {
      debugPrint('[AuthService] Error fetching user roles: $e');
      return [];
    }
  }

  /// Get the active role for the user
  /// If no activeRole set, returns the first role or null
  static Future<String?> getActiveRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final activeRole = doc.data()?['activeRole'] as String?;
      debugPrint('[AuthService] Active role: $activeRole');
      return activeRole;
    } catch (e) {
      debugPrint('[AuthService] Error fetching active role: $e');
      return null;
    }
  }

  /// Set the active role for the user
  static Future<void> setActiveRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'activeRole': role,
      });
      debugPrint('[AuthService] Active role updated to: $role');
    } catch (e) {
      debugPrint('[AuthService] Error setting active role: $e');
      rethrow;
    }
  }

  /// Add a new role to user's roles array
  static Future<void> addUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'roles': FieldValue.arrayUnion([role]),
        'activeRole': role, // Set as active role
      });
      debugPrint('[AuthService] Role added: $role');
    } catch (e) {
      debugPrint('[AuthService] Error adding role: $e');
      rethrow;
    }
  }

  /// Initialize user roles if they don't exist
  static Future<void> initializeUserRoles(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'roles': [],
          'activeRole': null,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[AuthService] User document initialized');
      } else if (doc.data()?['roles'] == null) {
        // Initialize roles if missing
        await _firestore.collection('users').doc(uid).update({
          'roles': [],
          'activeRole': null,
        });
        debugPrint('[AuthService] User roles initialized');
      }
    } catch (e) {
      debugPrint('[AuthService] Error initializing user roles: $e');
      rethrow;
    }
  }

  /// Get current user's role after login
  /// Returns the active role if set, otherwise the first available role
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[AuthService] No user logged in');
      return null;
    }

    final uid = user.uid;

    try {
      // Initialize roles if needed
      await initializeUserRoles(uid);

      // Get active role
      final activeRole = await getActiveRole(uid);
      if (activeRole != null) {
        return activeRole;
      }

      // Fall back to first available role
      final roles = await getUserRoles(uid);
      if (roles.isNotEmpty) {
        await setActiveRole(uid, roles.first);
        return roles.first;
      }

      debugPrint('[AuthService] No roles assigned to user');
      return null;
    } catch (e) {
      debugPrint('[AuthService] Error getting current user role: $e');
      return null;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('[AuthService] User logged out');
    } catch (e) {
      debugPrint('[AuthService] Error during logout: $e');
      rethrow;
    }
  }
}
