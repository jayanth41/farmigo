import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory FirestoreUserService() {
    return _instance;
  }

  FirestoreUserService._internal();

  static const String _usersCollection = 'users';

  /// Create or update user profile in Firestore
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
      debugPrint('✅ User profile saved: ${profile.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving user profile: $e');
      return false;
    }
  }

  /// Fetch user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        debugPrint('✅ User profile fetched: ${doc.data()?['email']}');
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Update specific fields in user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updates);
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
      await _firestore.collection(_usersCollection).doc(uid).delete();
      debugPrint('✅ User profile deleted: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user profile: $e');
      return false;
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking user profile: $e');
      return false;
    }
  }
}
