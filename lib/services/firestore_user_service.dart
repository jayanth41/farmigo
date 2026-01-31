import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    createdAt: _parseDate(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
  );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // attempt to parse as int
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // fallback
    return DateTime.now();
  }
}

/// Firestore service for managing user profiles
class FirestoreUserService {
  static final FirestoreUserService _instance = FirestoreUserService._internal();
  final _supabase = Supabase.instance.client;
  // Simple in-memory cache to avoid repeated reads on rebuilds
  final Map<String, UserProfile> _cache = {};

  factory FirestoreUserService() {
    return _instance;
  }

  FirestoreUserService._internal();

  static const String _usersCollection = 'users';

  /// Create or update user profile in Firestore
  Future<bool> saveUserProfile(UserProfile profile) async {
    // enforce that a signed-in user exists
    final current = _supabase.auth.currentUser;
    if (current == null) {
      debugPrint('⚠️ saveUserProfile: no authenticated user');
      return false;
    }

    if (!await NetworkUtils.hasNetwork()) {
      debugPrint('⚠️ No network, saveUserProfile skipped');
      return false;
    }

    try {
  await _supabase.from(_usersCollection).upsert(profile.toJson());
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
    // return cached value when available
    if (_cache.containsKey(uid)) return _cache[uid];

    try {
      final resp = await _supabase.from(_usersCollection).select().eq('uid', uid).maybeSingle();
      if (resp == null) return null;
      final map = Map<String, dynamic>.from(resp as Map);
      final profile = UserProfile.fromJson(map);
      _cache[uid] = profile;
      debugPrint('✅ User profile fetched: ${map['email']}');
      return profile;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Update specific fields in user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await _supabase.from(_usersCollection).update(updates).eq('uid', uid);
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
    try {
      await _supabase.from(_usersCollection).delete().eq('uid', uid);
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
    try {
      final res = await _supabase.from(_usersCollection).select('uid').eq('uid', uid).maybeSingle();
      if (res == null) return false;
      _cache[uid] = UserProfile.fromJson(Map<String, dynamic>.from(res as Map));
      return true;
    } catch (e) {
      debugPrint('❌ Error checking user profile: $e');
      return false;
    }
  }
}
