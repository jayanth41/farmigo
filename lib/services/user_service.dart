import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a user row if it doesn't already exist
  Future<void> createUserIfNotExists({
    required String name,
    required String phone,
    String role = 'user',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _client.from('users').insert({
          'id': user.id,
          'name': name,
          'phone': phone,
          'role': role,
        });
      }
    } catch (e) {
      debugPrint('createUserIfNotExists error: $e');
    }
  }

  /// Fetch logged-in user's profile
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data == null ? null : Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('users').update({
        'name': name,
        'phone': phone,
      }).eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }
}
