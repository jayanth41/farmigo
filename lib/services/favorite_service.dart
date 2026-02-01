import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  /// Favorites persistence not implemented in this migration. These are
  /// no-op implementations to keep the app stable. Replace with Firestore
  /// when you want persistent favorites.

  Future<void> addFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    debugPrint('addFavorite called for ${user.uid} -> $propertyId (not saved)');
    return;
  }

  Future<void> removeFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    debugPrint('removeFavorite called for ${user.uid} -> $propertyId (not removed)');
    return;
  }

  Future<bool> isFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    debugPrint('isFavorite called for ${user.uid} -> $propertyId (default false)');
    return false;
  }
}
