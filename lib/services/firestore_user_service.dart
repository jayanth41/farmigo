import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'loginType': loginType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
        loginType: json['loginType'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      );

}

/// Firestore service for managing user profiles
class FirestoreUserService {
  static final FirestoreUserService _instance = FirestoreUserService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Simple in-memory cache to avoid repeated reads on rebuilds
  final Map<String, UserProfile> _cache = {};

  factory FirestoreUserService() {
    return _instance;
  }

  FirestoreUserService._internal();

  static const String _usersCollection = 'users';

  Future<bool> saveUserProfile(UserProfile profile) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      debugPrint('⚠️ saveUserProfile: no authenticated user');
      return false;
    }

    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ No network, saveUserProfile skipped');
      return false;
    }

    try {
      await _firestore.collection(_usersCollection).doc(profile.uid).set(profile.toJson(), SetOptions(merge: true));
      _cache[profile.uid] = profile;
      debugPrint('✅ User profile saved: ${profile.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving user profile: $e');
      return false;
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid];

    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      final map = doc.data() ?? {};
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(map));
      _cache[uid] = profile;
      debugPrint('✅ User profile fetched: ${map['email']}');
      return profile;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await _firestore.collection(_usersCollection).doc(uid).set(updates, SetOptions(merge: true));
      _cache.remove(uid);
      debugPrint('✅ User profile updated: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      return false;
    }
  }

  Future<bool> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      _cache.remove(uid);
      debugPrint('✅ User profile deleted: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user profile: $e');
      return false;
    }
  }

  Future<bool> userProfileExists(String uid) async {
    if (_cache.containsKey(uid)) return true;
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return false;
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(doc.data() ?? {}));
      _cache[uid] = profile;
      return true;
    } catch (e) {
      debugPrint('❌ Error checking user profile: $e');
      return false;
    }
  }
}
