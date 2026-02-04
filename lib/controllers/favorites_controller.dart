import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farmhouse_model.dart';

class FavoritesController extends GetxController {
  // Observable list of favorites
  final RxList<FarmhouseModel> favorites = <FarmhouseModel>[].obs;

  // SharedPreferences instance
  late SharedPreferences _prefs;

  // Storage key
  static const String _favoritesKey = 'favorites_list';

  @override
  void onInit() {
    super.onInit();
    _initializePreferences();
  }

  // Initialize SharedPreferences and load saved favorites
  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await loadFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> loadFavorites() async {
    try {
      final String? jsonString = _prefs.getString(_favoritesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<FarmhouseModel> loadedFavorites = jsonList
            .map((item) => FarmhouseModel.fromJson(item as Map<String, dynamic>))
            .toList();
        favorites.assignAll(loadedFavorites);
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final List<Map<String, dynamic>> jsonList =
          favorites.map((fav) => fav.toJson()).toList();
      await _prefs.setString(_favoritesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // Add to favorites
  Future<void> addFavorite(FarmhouseModel farmhouse) async {
    // Always update local state so favorites work for signed-out users as well.
    // If a user is signed in, mirror changes to Firestore; otherwise skip server ops.
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        // To avoid duplicates and support toggle behavior if a favorite already exists
        // in Firestore for this user + listing, check and delete it instead of creating a
        // duplicate document. This keeps server state consistent even if local state
        // is out of sync.
        final query = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('listingId', isEqualTo: farmhouse.id)
            .get();

        if (query.docs.isNotEmpty) {
          // Favorite already exists on server: delete those docs (toggle off)
          for (final doc in query.docs) {
            await doc.reference.delete();
          }

          // Also remove from local favorites if present
          favorites.removeWhere((fav) => fav.id == farmhouse.id);
          await _saveFavorites();
          return;
        }

        // No existing favorite on server — create one
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': user.uid,
          'listingId': farmhouse.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local state for both signed-in and guest users
      if (!isFavorited(farmhouse.id)) {
        favorites.add(farmhouse);
        await _saveFavorites();
      }
    } catch (e) {
      debugPrint('Failed to add/remove favorite in Firestore: $e');
      // Ensure local state is still updated even if Firestore operations fail
      if (!isFavorited(farmhouse.id)) {
        favorites.add(farmhouse);
        await _saveFavorites();
      }
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String farmhouseId) async {
    favorites.removeWhere((fav) => fav.id == farmhouseId);
    await _saveFavorites();
    // Remove from Firestore favorites collection (all matching docs)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final query = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('listingId', isEqualTo: farmhouseId)
            .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to remove favorite from Firestore: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(FarmhouseModel farmhouse) async {
    if (isFavorited(farmhouse.id)) {
      await removeFavorite(farmhouse.id);
    } else {
      await addFavorite(farmhouse);
    }
  }

  // Check if farmhouse is favorited
  bool isFavorited(String farmhouseId) {
    return favorites.any((fav) => fav.id == farmhouseId);
  }

  // Get favorite count
  int getFavoriteCount() {
    return favorites.length;
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    favorites.clear();
    await _saveFavorites();
  }
}