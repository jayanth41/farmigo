import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final supabase = Supabase.instance.client;

  /// Add to favorites
  Future<void> addFavorite(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('favorites').insert({
      'user_id': user.id,
      'property_id': propertyId,
    });
  }

  /// Remove from favorites
  Future<void> removeFavorite(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('property_id', propertyId);
  }

  /// Check if favorited
  Future<bool> isFavorite(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final res = await supabase
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('property_id', propertyId)
        .maybeSingle();

    return res != null;
  }
}
