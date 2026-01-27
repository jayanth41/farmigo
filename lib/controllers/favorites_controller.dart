import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
    if (!isFavorited(farmhouse.id)) {
      favorites.add(farmhouse);
      await _saveFavorites();
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String farmhouseId) async {
    favorites.removeWhere((fav) => fav.id == farmhouseId);
    await _saveFavorites();
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