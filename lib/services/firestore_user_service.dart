import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_helper.dart';
import 'network_utils.dart';

/// User profile model
class UserProfile {
  final String uid;
  final String email;
  String? name;
  String? phone;
  String? photoUrl;
  String? loginType; // 'email', 'google', 'phone'
  final DateTime createdAt;
  DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.loginType,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'phone': phone,
    'photoUrl': photoUrl,
    'loginType': loginType,
    'createdAt': createdAt,
    'updatedAt': updatedAt ?? DateTime.now(),
  };

  // Create from Firestore document
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
    loginType: json['loginType'] as String?,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] as Timestamp).toDate()
        : null,
  );
}

/// Firestore service for managing user profiles
class FirestoreUserService {
  static final FirestoreUserService _instance = FirestoreUserService._internal();
  final FirebaseFirestore? _firestore = FirebaseHelper.isLikelyAvailable() ? FirebaseFirestore.instance : null;
  // Simple in-memory cache to avoid repeated reads on rebuilds
  final Map<String, UserProfile> _cache = {};

  factory FirestoreUserService() {
    return _instance;
  }

  FirestoreUserService._internal();

  static const String _usersCollection = 'users';

  /// Create or update user profile in Firestore
  Future<bool> saveUserProfile(UserProfile profile) async {
    // enforce that a signed-in user exists (compatible with simple Firestore rules)
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ saveUserProfile: no authenticated user');
      return false;
    }

    if (_firestore == null) {
      debugPrint('⚠️ Firestore unavailable, saveUserProfile skipped');
      return false;
    }

    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ No network, saveUserProfile skipped');
      return false;
    }

    try {
      final db = _firestore!;
      await db
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
      // update cache
      _cache[profile.uid] = profile;
      debugPrint('✅ User profile saved: ${profile.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving user profile: $e');
      return false;
    }
  }

  /// Fetch user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    // enforce auth for reads to satisfy rules that require request.auth != null
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ getUserProfile: no authenticated user');
      return null;
    }

    // return cached value when available
    if (_cache.containsKey(uid)) return _cache[uid];

    if (_firestore == null) {
      debugPrint('⚠️ Firestore unavailable, getUserProfile returning null');
      return null;
    }

    try {
      final db = _firestore!;
      final doc = await db
        .collection(_usersCollection)
        .doc(uid)
        .get();

      if (doc.exists) {
        final profile = UserProfile.fromJson(doc.data() as Map<String, dynamic>);
        _cache[uid] = profile;
        debugPrint('✅ User profile fetched: ${doc.data()?['email']}');
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Update specific fields in user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ updateUserProfile: no authenticated user');
      return false;
    }

    if (_firestore == null) {
      debugPrint('⚠️ Firestore unavailable, updateUserProfile skipped');
      return false;
    }

    try {
      updates['updatedAt'] = DateTime.now();
      final db = _firestore!;
      await db
        .collection(_usersCollection)
        .doc(uid)
        .update(updates);
      // invalidate cache for uid
      _cache.remove(uid);
      debugPrint('✅ User profile updated: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      return false;
    }
  }

  /// Update user name
  Future<bool> updateUserName(String uid, String name) async {
    return updateUserProfile(uid, {'name': name});
  }

  /// Update user phone
  Future<bool> updateUserPhone(String uid, String phone) async {
    return updateUserProfile(uid, {'phone': phone});
  }

  /// Update user photo
  Future<bool> updateUserPhoto(String uid, String photoUrl) async {
    return updateUserProfile(uid, {'photoUrl': photoUrl});
  }

  /// Delete user profile (when account is deleted)
  Future<bool> deleteUserProfile(String uid) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ deleteUserProfile: no authenticated user');
      return false;
    }

    if (_firestore == null) {
      debugPrint('⚠️ Firestore unavailable, deleteUserProfile skipped');
      return false;
    }

    try {
      final db = _firestore!;
      await db.collection(_usersCollection).doc(uid).delete();
      _cache.remove(uid);
      debugPrint('✅ User profile deleted: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user profile: $e');
      return false;
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    if (_cache.containsKey(uid)) return true;

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ userProfileExists: no authenticated user');
      return false;
    }

    if (_firestore == null) {
      debugPrint('⚠️ Firestore unavailable, userProfileExists returning false');
      return false;
    }

    try {
      final db = _firestore!;
      final doc = await db
        .collection(_usersCollection)
        .doc(uid)
        .get();
      final exists = doc.exists;
      if (exists) {
        _cache[uid] = UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return exists;
    } catch (e) {
      debugPrint('❌ Error checking user profile: $e');
      return false;
    }
  }
}
